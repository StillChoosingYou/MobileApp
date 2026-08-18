from rembg import remove
from PIL import Image

input = Image.open("pgpc_logo.png")
output = remove(input)

output.save("output.png")