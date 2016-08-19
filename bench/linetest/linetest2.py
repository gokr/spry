lines = []
with open('lotslines') as ins:
    for line in ins:
        lines.append(line)

print "Lines: " + str(len(lines))
