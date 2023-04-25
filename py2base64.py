import base64


b64e = base64.b64encode(""" 
def hello():
     print('hello world!')
hello() """.encode())
#print(b64e)
#exit()

py_code_file = 'process-yaml-stdin.py'
with open(py_code_file, 'r') as f:
    py_code = f.read()
b64e = base64.b64encode(py_code.encode())
print(b64e)

b64d = base64.b64decode(b64e)
print(b64d)
# test
#exec(b64d)
