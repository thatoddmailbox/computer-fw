file = open("font.s", "r")
rotated = open("font_rotated.s", "w")
char_lines = []
for line in file:
	if line.strip() == "font:" or len(line) < 3 or line[1] != "d" or line[2] != "b":
		rotated.write(line)
		continue
	char_line = line.strip().split(" ")[1]
	char_lines.append(char_line[2:])
	if len(char_lines) == 8:
		rotated_lines = []
		for i in xrange(0,8):
			rotated_line = ""
			for j in xrange(0,8):
				rotated_line += char_lines[j][i]
			rotated_lines.append(rotated_line)
		for line in rotated_lines:
			rotated.write("\tdb 0b" + line + "\n")
		char_lines = []