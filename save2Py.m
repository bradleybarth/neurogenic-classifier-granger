function save2Py(name)

LOADFILE = 'data/giData.mat';
SAVEFILE = ['data/pyData/',name,'.json'];

load(LOADFILE, 'gcArray', 'labels', 'dataOpts')

[~,~,big] = size(gcArray);
if big > 3000
    data1 = jsonencode({gcArray(:,:,1:floor(big/2)), labels});
    data2 = jsonencode({gcArray(:,:,floor(big/2)+1:big), labels});
else
    data = jsonencode({gcArray, labels});
end


if big > 3000
    SAVEFILE = ['data/pyData/',name,'_1.json'];
    filename = sprintf(SAVEFILE);
    fID = fopen(filename,'w+');
    fprintf(fID,'%s',data1);
    
    SAVEFILE = ['data/pyData/',name,'_2.json'];
    filename = sprintf(SAVEFILE);
    fID = fopen(filename,'w+');
    fprintf(fID,'%s',data2);
else
    filename = sprintf(SAVEFILE);
    fID = fopen(filename,'w+');
    fprintf(fID,'%s',data);
end