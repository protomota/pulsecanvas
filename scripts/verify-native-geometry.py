import math,struct,json,pathlib,sys,hashlib
from unicorn import Uc,UC_ARCH_ARM64,UC_MODE_ARM,UC_HOOK_CODE
from unicorn.arm64_const import UC_ARM64_REG_D0,UC_ARM64_REG_X30,UC_ARM64_REG_SP,UC_ARM64_REG_PC
repo=pathlib.Path(__file__).resolve().parent.parent
binary=pathlib.Path(sys.argv[1])
results_path=pathlib.Path(sys.argv[2]) if len(sys.argv)>2 else repo/'docs/native-decompilation/geometry-swift-results.tsv'
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
uc=Uc(UC_ARCH_ARM64,UC_MODE_ARM)
for name,vm,vms,fo,fs in segments:
 if fs==0:continue
 size=(vms+4095)&~4095
 uc.mem_map(vm,size)
 uc.mem_write(vm,data[fo:fo+fs])
stack=0x90000000;uc.mem_map(stack,0x10000)
sentinel=0xa0000000;uc.mem_map(sentinel,0x1000)
mathcalls={0x100763d18:math.exp,0x1007644e0:math.pow,0x100763b8c:math.cos,0x100764828:math.sin,0x100763ad8:math.atan}
def readfloat(reg):return struct.unpack('<d',struct.pack('<Q',uc.reg_read(reg)))[0]
def writefloat(reg,value):uc.reg_write(reg,struct.unpack('<Q',struct.pack('<d',value))[0])
def hook(uc,address,size,user):
 if address not in mathcalls:return
 args=[readfloat(UC_ARM64_REG_D0)]
 if address==0x1007644e0:args.append(readfloat(UC_ARM64_REG_D0+1))
 try:value=mathcalls[address](*args)
 except ValueError:value=float('nan')
 except OverflowError:value=float('inf')
 writefloat(UC_ARM64_REG_D0,value)
 uc.reg_write(UC_ARM64_REG_PC,uc.reg_read(UC_ARM64_REG_X30))
uc.hook_add(UC_HOOK_CODE,hook)
catalog=json.loads((repo/'docs/native-decompilation/formula-catalog.json').read_text())
results={(int(v[0]),int(v[1])):float(v[2]) for line in open(results_path) if len(v:=line.strip().split('\t'))==3}
samples=[(12.5,18.75),(-33.25,71.125),(1.2,1.1),(0,0),(239.5,-239.5)]
count=0
for sample_index,(x,y) in enumerate(samples):
 for entry in catalog:
  uc.reg_write(UC_ARM64_REG_SP,stack+0x8000)
  uc.reg_write(UC_ARM64_REG_X30,sentinel)
  for i,value in enumerate((x,y,0,240,240)):writefloat(UC_ARM64_REG_D0+i,value)
  uc.emu_start(int(entry['function'],16),sentinel,count=500)
  native=readfloat(UC_ARM64_REG_D0);swift=results[(sample_index,entry['id'])]
  if math.isnan(native):match=math.isnan(swift)
  elif math.isinf(native):match=native==swift
  else:match=math.isfinite(swift) and abs(native-swift)<=max(abs(native),abs(swift),1)*1e-13
  assert match,(entry,x,y,native,swift)
  count+=1
print(f'PASS: {count} comparisons, all 79 reconstructed Swift formulas match original native ARM64 instructions at 5 samples, including origin and negative coordinates (Unicorn emulation, relative tolerance 1e-13, NaN/Inf classified)')
