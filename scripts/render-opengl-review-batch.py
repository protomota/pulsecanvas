#!/usr/bin/env python3
"""Render resumable, isolated preset review batches; never prune or change Finder tags."""
import argparse, csv, datetime, hashlib, json, re, subprocess, time
from pathlib import Path

MUSIC_VOLUME = Path('/Volumes/Music')
MEDIA_ROOT = MUSIC_VOLUME / 'Codex Media/PulseCanvas Studio'


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def run(command, **kwargs):
    return subprocess.run(command, check=True, capture_output=True, **kwargs)


def inspect_video(path):
    info = json.loads(run(['ffprobe', '-v', 'error', '-count_frames', '-show_streams', '-show_format', '-of', 'json', str(path)]).stdout)
    video = next(s for s in info['streams'] if s['codec_type'] == 'video')
    audio = next(s for s in info['streams'] if s['codec_type'] == 'audio')
    rate = video['avg_frame_rate'].split('/')
    duration = float(info['format']['duration'])
    assert abs(duration - 10) < .06 and int(video['nb_read_frames']) == 300, info
    assert (video['width'], video['height']) == (1280, 720) and int(rate[0])/int(rate[1]) == 30
    pixels = run(['ffmpeg', '-v', 'error', '-i', str(path), '-vf', 'fps=1,scale=160:90', '-f', 'rawvideo', '-pix_fmt', 'rgb24', '-']).stdout
    assert len(pixels) >= 9 * 160 * 90 * 3
    means = [sum(pixels[i:i+43200])/43200 for i in range(0,len(pixels)-43199,43200)]
    return {'duration':duration,'decodedFrames':int(video['nb_read_frames']),'width':1280,'height':720,'fps':30,'audioCodec':audio['codec_name'],'sampledMeanRGB':means,'darkPreview':max(means)<2,'sha256':sha(path)}


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--source-root',type=Path,required=True)
    parser.add_argument('--review-root',type=Path,default=MEDIA_ROOT/'Review and Renders/OpenGL-Effects-Review')
    parser.add_argument('--work-root',type=Path,default=MEDIA_ROOT/'Render Work/OpenGL',help='Render scratch storage on the mounted Music drive.')
    parser.add_argument('--batch',type=int,default=1)
    parser.add_argument('--count',type=int,default=100)
    parser.add_argument('--limit',type=int,help='Stop after this many completed clips; resume the same batch later.')
    args=parser.parse_args();root=args.source_root.resolve();review=args.review_root.resolve();work_root=args.work_root.resolve()
    if not MUSIC_VOLUME.is_mount():
        parser.error('Mount the Music drive before rendering. No main-drive fallback is used.')
    for destination in [review, work_root]:
        if MUSIC_VOLUME != destination and MUSIC_VOLUME not in destination.parents:
            parser.error('Review videos and render scratch files must be stored on /Volumes/Music.')
    folder=review/f'Batch-{args.batch:03d}';folder.mkdir(parents=True,exist_ok=True)
    work=work_root/f'batch-{args.batch:03d}';work.mkdir(parents=True,exist_ok=True)
    catalog_path=root/'Sources/PulseCanvas/Resources/ProjectM/catalog.json';catalog=json.loads(catalog_path.read_text())
    manifest_path=folder/'manifest.json'
    if manifest_path.exists():
        manifest=json.loads(manifest_path.read_text());assert manifest['catalogSHA256']==sha(catalog_path),'Catalog changed; preserve the old batch and use a new folder.'
        assert manifest['requestedVideos']==args.count
        for item in manifest['videos']:assert sha(folder/item['file'])==item['validation']['sha256'],'Existing rated video changed; do not overwrite it.'
    else:
        previous=review/f'Batch-{args.batch-1:03d}'/'manifest.json'
        start=json.loads(previous.read_text())['nextCatalogIndex'] if args.batch>1 else 0
        manifest={'batch':args.batch,'requestedVideos':args.count,'createdAt':datetime.datetime.now(datetime.timezone.utc).isoformat(),'sourceRoot':str(root),'catalogSHA256':sha(catalog_path),'catalogPresets':len(catalog),'startCatalogIndex':start,'nextCatalogIndex':start,'videos':[],'failures':[],'settings':{'durationSeconds':10,'warmupSeconds':2,'resolution':'1280x720','fps':30,'chaos':1,'brightness':1,'zoom':1,'motionBlur':0,'strobe':False,'audioStartSeconds':42,'intrinsicPresetColors':True},'status':'rendering'}
    audio=work/'soundtrack-12s.wav'
    if not audio.exists():run(['ffmpeg','-v','error','-ss','40','-i',str(root/'Sources/PulseCanvas/Resources/Audio/PulseCanvas.mp3'),'-t','12','-ar','44100','-ac','2','-c:a','pcm_s16le',str(audio)])
    manifest['soundtrackSHA256']=sha(root/'Sources/PulseCanvas/Resources/Audio/PulseCanvas.mp3')
    def save():
        manifest['updatedAt']=datetime.datetime.now(datetime.timezone.utc).isoformat();temporary=manifest_path.with_suffix('.json.tmp');temporary.write_text(json.dumps(manifest,indent=2)+'\n');temporary.replace(manifest_path)
        with (folder/'index.csv').open('w',newline='') as f:
            writer=csv.writer(f);writer.writerow(['file','title','category','presetID','upstreamPath','originalTitle','presetSHA256','darkPreview'])
            for v in manifest['videos']:writer.writerow([v['file'],v['title'],v['category'],v['id'],v['path'],v.get('originalTitle',''),v['presetSHA256'],v['validation']['darkPreview']])
    save()
    completed_this_run=0
    while len(manifest['videos'])<args.count and manifest['nextCatalogIndex']<len(catalog):
        index=manifest['nextCatalogIndex'];entry=catalog[index];number=index+1
        title=re.sub(r'[/:\\\x00-\x1f]','-',entry['title'])
        filename=f'{number:04d} - {title}.mp4';target=folder/filename
        assert not target.exists(),'Refusing to overwrite a review clip with existing Finder tags.'
        raw=work/f'{number:04d}-warmup.mp4';log=work/f'{number:04d}.log';began=time.monotonic()
        print(f'RENDER {len(manifest["videos"])+1}/{args.count}: {filename}',flush=True)
        try:
            with log.open('wb') as f:
                subprocess.run([str(root/'.build/curation/render-opengl-review'),str(index),str(audio),str(raw)],cwd=root,stdout=f,stderr=subprocess.STDOUT,check=True,timeout=180)
            partial=work/f'{number:04d}-final.mp4'
            run(['ffmpeg','-v','error','-ss','2','-i',str(raw),'-t','10','-map','0:v:0','-map','0:a:0','-c:v','h264_videotoolbox','-b:v','8M','-pix_fmt','yuv420p','-r','30','-c:a','aac','-b:a','192k','-movflags','+faststart','-metadata',f'title={entry["title"]}','-metadata',f'comment={entry["id"]}',str(partial)],timeout=60)
            validation=inspect_video(partial)
            partial.replace(target)
            record=dict(entry,catalogIndex=index,file=filename,presetSHA256=sha(root/'Sources/PulseCanvas/Resources/ProjectM/Presets'/entry['path']),validation=validation,renderSeconds=round(time.monotonic()-began,2))
            manifest['videos'].append(record);completed_this_run+=1
            print(f'PASS {len(manifest["videos"])}/{args.count}: 300 decoded frames, 10s, audio, {record["renderSeconds"]}s render'+(' — dark preview flagged' if validation['darkPreview'] else ''),flush=True)
            raw.unlink(missing_ok=True)
        except Exception as error:
            manifest['failures'].append(dict(entry,catalogIndex=index,error=str(error),log=str(log)))
            print(f'FAILED {filename}: {error}; logged and continuing without changing the app library.',flush=True)
        manifest['nextCatalogIndex']=index+1;save()
        if args.limit and completed_this_run>=args.limit:break
    if len(manifest['videos'])==args.count:manifest['status']='ready-for-review'
    elif manifest['nextCatalogIndex']>=len(catalog):manifest['status']='catalog-exhausted'
    save();print(f'BATCH {manifest["status"]}: {len(manifest["videos"])} videos, {len(manifest["failures"])} render failures, {folder}',flush=True)

if __name__=='__main__':main()
