import re,struct,json,pathlib,collections,sys,hashlib
repo=pathlib.Path(__file__).resolve().parent.parent
artifacts=repo/'docs/native-decompilation'
binary=pathlib.Path(sys.argv[1])
output=pathlib.Path(sys.argv[2]) if len(sys.argv)>2 else repo/'.build/recovered/recovered-formula-expressions.json'
data=binary.read_bytes()
assert hashlib.sha256(data).hexdigest()=='de9f62b020b16e1ed1d34182f35ac7fe6b0e5fb3815e71a2092e7080744ebdfa','The provided native app differs from the analyzed build'
ncmds=struct.unpack_from('<I',data,16)[0];pos=32;segments=[]
for _ in range(ncmds):
 cmd,size=struct.unpack_from('<II',data,pos)
 if cmd==0x19:
  name=data[pos+8:pos+24].split(b'\0')[0].decode()
  vm,vms,fo,fs=struct.unpack_from('<QQQQ',data,pos+24)
  segments.append((name,vm,vms,fo,fs))
 pos+=size
def offset(addr):
 for name,vm,vms,fo,fs in segments:
  if vm<=addr<vm+fs:return fo+addr-vm
 raise ValueError(hex(addr))
catalog=json.loads((artifacts/'formula-catalog.json').read_text())
assembly=(artifacts/'formula-assembly.txt').read_text()
code=(artifacts/'original-formula-pseudocode.c').read_text()
functions={int(r.split('\t')[0],16):int(r.rstrip().split('\t')[2]) for r in open(artifacts/'functions.tsv')}
lines=[]
for m in re.finditer(r'^([0-9a-f]+): [0-9a-f]+[ \t]+(\S+)[ \t]*(.*)$',assembly,re.M):
 lines.append((int(m[1],16),m[2],m[3].split(';')[0].strip()))
mathcalls={}
for entry in catalog:
 addr=int(entry['function'],16);size=functions[addr];ops=[o for o in lines if addr<=o[0]<addr+size]
 cm=re.search(r'/\* '+format(addr,'x')+r' .*?(?=/\* 100|\Z)',code,re.S)[0]
 names=re.findall(r'_(exp|cos|sin|atan|pow)\(',cm)
 branches=[int(re.search(r'0x([0-9a-f]+)',o[2])[1],16) for o in ops if o[1] in ('bl','b')]
 assert len(names)==len(branches),(entry,len(names),branches)
 for target,name in zip(branches,names):
  assert target not in mathcalls or mathcalls[target]==name
  mathcalls[target]=name
print('Resolved imported math calls',mathcalls)
recovered=[]
for entry in catalog:
 addr=int(entry['function'],16);size=functions[addr];ops=[o for o in lines if addr<=o[0]<addr+size]
 scalar={(0,0):'x',(1,0):'y',(2,0):'0.0',(3,0):'xMax',(4,0):'yMax'};integer={};statements=[]
 def register(s):
  m=re.fullmatch(r'[dvq](\d+)(?:\[(\d)\])?',s);assert m,s
  return int(m[1]),int(m[2] or 0)
 def get(s):return scalar[register(s)]
 def put(s,expr):
  var='value'+str(len(statements));statements.append((var,expr));scalar[register(s)]=var
 for pc,op,arg in ops:
  operands=[v.strip() for v in arg.split(',')]
  if op in ('stp','ldp','ret'):continue
  if op=='adrp':integer[operands[0]]=int(re.search(r'0x([0-9a-f]+)',operands[1])[1],16)
  elif op=='add':
   if operands[0]=='x29':continue
   integer[operands[0]]=integer[operands[1]]+int(operands[2].split()[0][1:],0)
  elif op=='mov':
   if operands[1]=='sp':continue
   integer[operands[0].replace('w','x')]=int(operands[1][1:],0)
  elif op=='movk':
   shift=int(re.search(r'lsl #(\d+)',arg)[1]);mask=0xffff<<shift
   integer[operands[0]]=(integer[operands[0]]&~mask)|(int(operands[1][1:],0)<<shift)
  elif op=='ldr':
   m=re.search(r'\[(x\d+), #(0x[0-9a-f]+|\d+)\]',arg);assert m,(op,arg)
   a=integer[m[1]]+int(m[2],0);dest=operands[0]
   if dest.startswith('q'):
    scalar[register(dest)]=repr(struct.unpack_from('<d',data,offset(a))[0]);scalar[(register(dest)[0],1)]=repr(struct.unpack_from('<d',data,offset(a+8))[0])
   else:scalar[register(dest)]=repr(struct.unpack_from('<d',data,offset(a))[0])
  elif op=='fmov':
   source=operands[1]
   if source.startswith('#'):scalar[register(operands[0])]=repr(float(source[1:]))
   elif source.startswith('x'):scalar[register(operands[0])]=repr(struct.unpack('<d',struct.pack('<Q',integer[source]&0xffffffffffffffff))[0])
   else:scalar[register(operands[0])]=get(source)
  elif op=='mov.d':scalar[register(operands[0])]=get(operands[1])
  elif op=='dup.2d':
   v=get(operands[1]);n=register(operands[0])[0];scalar[n,0]=v;scalar[n,1]=v
  elif op in ('fmul.2d','fsub.2d'):
   d,a,b=[register(v)[0] for v in operands];symbol='*' if op.startswith('fmul') else '-';expressions=[f'({scalar[a,i]} {symbol} {scalar[b,i]})' for i in range(2)]
   for i in range(2):put(f'v{d}[{i}]',expressions[i])
  elif op in ('fmul','fadd','fsub','fdiv','fnmul','fabd'):
   a,b=get(operands[1]),get(operands[2]);symbol={'fmul':'*','fadd':'+','fsub':'-','fdiv':'/','fnmul':'*','fabd':'-'}[op];expr=f'({a} {symbol} {b})'
   if op=='fnmul':expr='-'+expr
   if op=='fabd':expr='abs'+expr
   put(operands[0],expr)
  elif op in ('fabs','fsqrt','frintp'):
   put(operands[0],{'fabs':'abs','fsqrt':'sqrt','frintp':'ceil'}[op]+'('+get(operands[1])+')')
  elif op in ('b','bl'):
   target=int(re.search(r'0x([0-9a-f]+)',arg)[1],16);name=mathcalls[target];expr=name+'('+get('d0')+(', '+get('d1') if name=='pow' else '')+')';put('d0',expr)
  else:raise Exception((pc,op,arg))
 # Only retain operations used by the return value (SIMD high-lane operations may be dead).
 needed={get('d0')};selected=[]
 for name,expression in reversed(statements):
  if name in needed:
   selected.append((name,expression));needed.update(re.findall(r'\bvalue\d+\b',expression))
 recovered.append({**entry,'statements':list(reversed(selected)),'result':get('d0')})
output.parent.mkdir(parents=True,exist_ok=True)
output.write_text(json.dumps(recovered,indent=2))
print('Recovered all',len(recovered),'formula bodies from ARM64 instructions')
