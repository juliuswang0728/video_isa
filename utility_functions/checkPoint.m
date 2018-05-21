function validFlag = checkPoint(row, col, h, w, halfFoveaSize)

validFlag = 1;

if row < halfFoveaSize + 1 || row > (h - halfFoveaSize -1)
    validFlag = 0;
end

if col < halfFoveaSize + 1 || col > (w - halfFoveaSize -1)
    validFlag = 0;
end