import sys 
f = open(sys.argv[1], "rb")
bys = f.read()
f.close()
st = input("Program start address (in hex, e.g. 1d00): ")
st = int(st, 16)
i = 0
ln = 10
ostr=""
ostr+=f"{ln} for a={st} to {st+len(bys)-1}\n"
ln += 10
ostr+=f"{ln} read b : poke a,b : next a\n"
ln += 10
ostr+=f"{ln} data "
while i < len(bys):
    ostr+= str(bys[i])
    i = i + 1
    if i % 16 == 0:
        ln += 10
        ostr+=f"\n{ln} data "
    else:
        ostr+=","
print(ostr[:-1])
f = open("install.bas", "w")
f.write(ostr[:-1])
f.close()
print("install.bas written.")