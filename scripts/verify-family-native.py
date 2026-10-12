import struct,math,json,pathlib,sys
from unicorn import Uc,UC_ARCH_ARM64,UC_MODE_ARM,UC_HOOK_CODE
from unicorn.arm64_const import *
# Requires an ARM64 Mach-O supplied explicitly; it is never modified.
if len(sys.argv) != 3: raise SystemExit("Usage: verify-family-native.py MACH_O SWIFT_RESULTS_TSV")
data=pathlib.Path(sys.argv[1]).read_bytes()
ncmds=struct.unpack_from('<I',data,16)[0];pos=32;segments=[]
for _ in range(ncmds):
 cmd,size=struct.unpack_from('<II',data,pos)
 if cmd==0x19:
  name=data[pos+8:pos+24].split(b'\0')[0].decode();vm,vms,fo,fs=struct.unpack_from('<QQQQ',data,pos+24);segments.append((name,vm,vms,fo,fs))
 pos+=size
uc=Uc(UC_ARCH_ARM64,UC_MODE_ARM)
for name,vm,vms,fo,fs in segments:
 if fs:uc.mem_map(vm,(vms+4095)&~4095);uc.mem_write(vm,data[fo:fo+fs])
base=0x90000000;uc.mem_map(base,0x10000);sp=base+0x8000;params=base+0x100;array=base+0x300
uc.mem_write(array+0x10,struct.pack('<QQ',0,1000000))
def rd(reg,fmt='d'):return struct.unpack('<'+fmt,uc.reg_read(reg).to_bytes(struct.calcsize(fmt),'little'))[0]
def wr(reg,val,fmt='d'):uc.reg_write(reg,int.from_bytes(struct.pack('<'+fmt,val),'little'))
def hook(uc,addr,size,u):
 if addr==0x100763d60:wr(UC_ARM64_REG_D0,math.fmod(rd(UC_ARM64_REG_D0),rd(UC_ARM64_REG_D1)))
 elif addr==0x100764e7c:wr(UC_ARM64_REG_D0,math.tan(rd(UC_ARM64_REG_D0)))
 elif addr==0x100764828:wr(UC_ARM64_REG_D0,math.sin(rd(UC_ARM64_REG_D0)))
 elif addr==0x1007639a0:
  a=rd(UC_ARM64_REG_D0);wr(UC_ARM64_REG_D0,math.sin(a));wr(UC_ARM64_REG_D1,math.cos(a))
 elif addr==0x1007639ac:
  a=rd(UC_ARM64_REG_S0,'f');wr(UC_ARM64_REG_S0,math.sin(a),'f');wr(UC_ARM64_REG_S1,math.cos(a),'f')
 else:return
 uc.reg_write(UC_ARM64_REG_PC,uc.reg_read(UC_ARM64_REG_X30))
uc.hook_add(UC_HOOK_CODE,hook)
def clear():
 for i in range(31):uc.reg_write(UC_ARM64_REG_X0+i,0)
 for i in range(32):uc.reg_write(UC_ARM64_REG_Q0+i,0)
 uc.reg_write(UC_ARM64_REG_SP,sp);uc.mem_write(params,b'\0'*200)
def run(a,b):uc.emu_start(a,b,count=2000)
results=[]
for line in open(sys.argv[2]):
 name,r,s,*values=line.strip().split('\t');r=int(r);s=int(s);swift=list(map(float,values));clear()
 if name=='tunnel':
  for off,fmt,val in [(0x18,'q',24000),(0x20,'q',20),(0x28,'f',3),(0x30,'d',2.5),(0x38,'f',.5),(0x48,'d',12),(0x50,'q',80),(0x58,'d',14),(0x60,'f',4),(0x70,'d',3)]:uc.mem_write(params+off,struct.pack('<'+fmt,val))
  uc.reg_write(UC_ARM64_REG_X23,params);uc.reg_write(UC_ARM64_REG_X20,r);uc.reg_write(UC_ARM64_REG_X19,r*20);uc.reg_write(UC_ARM64_REG_X21,24000);uc.reg_write(UC_ARM64_REG_X25,20)
  wr(UC_ARM64_REG_D10,20);wr(UC_ARM64_REG_D11,2*math.pi)
  run(0x1003abfe8,0x1003ac0e4);uc.reg_write(UC_ARM64_REG_X28,s);run(0x1003ac0e4,0x1003ac11c)
  # Default swapXY=false swaps raw pair.
  native=[rd(UC_ARM64_REG_D8),rd(UC_ARM64_REG_D13),rd(UC_ARM64_REG_S12,'f')]
  native[:2]=[struct.unpack('<f',struct.pack('<f',v))[0] for v in native[:2]]
 elif name=='morph':
  for off,fmt,val in [(0,'q',4000),(8,'q',100),(0x18,'d',2.5),(0x20,'f',3),(0x24,'f',.5),(0x28,'d',.0125),(0x30,'f',14),(0x34,'f',1),(0x38,'f',1)]:uc.mem_write(params+off,struct.pack('<'+fmt,val))
  uc.reg_write(UC_ARM64_REG_X21,params);uc.reg_write(UC_ARM64_REG_X22,array);uc.reg_write(UC_ARM64_REG_X23,r);uc.reg_write(UC_ARM64_REG_X27,40)
  wr(UC_ARM64_REG_D10,40);wr(UC_ARM64_REG_D12,2*math.pi);wr(UC_ARM64_REG_D14,2)
  run(0x1003bc3b0,0x1003bc48c);uc.reg_write(UC_ARM64_REG_X24,s);run(0x1003bc48c,0x1003bc510)
  native=list(struct.unpack('<4f',uc.reg_read(UC_ARM64_REG_Q0).to_bytes(16,'little')))[:3]
 elif name=='crystal':
  for off,fmt,val in [(0,'q',100),(8,'q',20),(0x10,'f',1),(0x14,'f',1),(0x18,'f',3),(0x1c,'f',1),(0x20,'f',4)]:uc.mem_write(params+off,struct.pack('<'+fmt,val))
  uc.reg_write(UC_ARM64_REG_X25,params);uc.reg_write(UC_ARM64_REG_X28,r);uc.reg_write(UC_ARM64_REG_X21,20);uc.reg_write(UC_ARM64_REG_X23,array);uc.reg_write(UC_ARM64_REG_W24,0x40c90fda);wr(UC_ARM64_REG_S8,20,'f')
  run(0x1003c3b10,0x1003c3b58);uc.reg_write(UC_ARM64_REG_X26,s);run(0x1003c3b58,0x1003c3b94)
  native=list(struct.unpack('<4f',uc.reg_read(UC_ARM64_REG_Q0).to_bytes(16,'little')))[:3]
 else:
  radial=0
  for _ in range(r):radial+=.00015225
  uc.reg_write(UC_ARM64_REG_X19,array)
  for reg,val in [(UC_ARM64_REG_D8,r*2),(UC_ARM64_REG_D9,1090),(UC_ARM64_REG_D10,math.pi),(UC_ARM64_REG_D11,180),(UC_ARM64_REG_D14,radial)]:wr(reg,val)
  run(0x1003db76c,0x1003db794);native=[rd(UC_ARM64_REG_D1),rd(UC_ARM64_REG_D0),0]
 match=all(abs(a-b)<=max(abs(a),abs(b),1)*1e-6 for a,b in zip(native,swift))
 print('PASS' if match else 'FAIL',name,r,s,native,swift)
 assert match,(name,r,s,native,swift)
 results.append(dict(kernel=name,ring=r,segment=s,position=native))

print('PASS:',len(results),'native ARM64 kernel samples match Swift positions')
