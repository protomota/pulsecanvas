"""Read-only native instruction parity check. Requires Python Unicorn.
Usage: verify-point-native.py ARM64_MACH_O FIXTURE_JSON
"""
import sys,struct,json,math,pathlib
from unicorn import Uc,UC_ARCH_ARM64,UC_MODE_ARM,UC_HOOK_CODE
from unicorn.arm64_const import *
if len(sys.argv)!=3:raise SystemExit(__doc__)
data=pathlib.Path(sys.argv[1]).read_bytes();commands=struct.unpack_from('<I',data,16)[0];pos=32
uc=Uc(UC_ARCH_ARM64,UC_MODE_ARM)
for _ in range(commands):
 command,size=struct.unpack_from('<II',data,pos)
 if command==0x19:
  vm,vms,offset,fs=struct.unpack_from('<QQQQ',data,pos+24)
  if fs:uc.mem_map(vm,(vms+4095)&~4095);uc.mem_write(vm,data[offset:offset+fs])
 pos+=size
base=0x90000000;uc.mem_map(base,0x10000);end=0xa0000000;uc.mem_map(end,0x1000)
def rd(reg):return struct.unpack('<d',struct.pack('<Q',uc.reg_read(reg)))[0]
def wr(reg,value):uc.reg_write(reg,struct.unpack('<Q',struct.pack('<d',value))[0])
mathcalls={0x1007639a0:'sincos',0x100764828:'sin',0x100763b8c:'cos',0x100764e7c:'tan'}
def hook(uc,address,size,user):
 if address not in mathcalls:return
 name=mathcalls[address];value=rd(UC_ARM64_REG_D0)
 if name=='sincos':wr(UC_ARM64_REG_D0,math.sin(value));wr(UC_ARM64_REG_D1,math.cos(value))
 else:wr(UC_ARM64_REG_D0,getattr(math,name)(value))
 uc.reg_write(UC_ARM64_REG_PC,uc.reg_read(UC_ARM64_REG_X30))
uc.hook_add(UC_HOOK_CODE,hook)
fixtures=json.loads(pathlib.Path(sys.argv[2]).read_text())
for fixture in fixtures:
 for i in range(31):uc.reg_write(UC_ARM64_REG_X0+i,0)
 for i in range(32):uc.reg_write(UC_ARM64_REG_Q0+i,0)
 uc.reg_write(UC_ARM64_REG_SP,base+0x8000);uc.reg_write(UC_ARM64_REG_X30,end);uc.reg_write(UC_ARM64_REG_X20,base+0x100)
 kernel=fixture['kernel'];pattern=fixture['pattern'];index=fixture['index'];length=fixture['length']
 if kernel=='point':
  args=[pattern,index,length,fixture['spread'],base+0x200,base+0x208]
  uc.mem_write(base+0x200,struct.pack('<qq',fixture['phaseA'],fixture['phaseB']));wr(UC_ARM64_REG_D0,fixture['amplitude']);address=0x1003a8eb0
 elif kernel=='stars':args=[index,length,pattern];address=0x1003a0adc
 else:args=[length,pattern,index];address=0x1003a86b8
 if kernel!='point':uc.reg_write(UC_ARM64_REG_S0,int.from_bytes(struct.pack('<f',fixture['amplitude']),'little'))
 for i,value in enumerate(args):uc.reg_write(UC_ARM64_REG_X0+i,value)
 uc.emu_start(address,end,count=2000)
 native=[rd(UC_ARM64_REG_D0+i) for i in range(3)] if kernel=='point' else [struct.unpack('<d',uc.mem_read(base+0x100+offset,8))[0] for offset in [0x38,0x40,0x48]]
 assert all(abs(a-b)<=max(abs(a),abs(b),1)*1e-13 for a,b in zip(native,fixture['position'])),(fixture,native)
print('PASS:',len(fixtures),'native instruction point-pattern fixtures verified')
