from rembg import remove
from PIL import Image

input = Image.open("input.png")
output = remove(input)

output.save("output.png")