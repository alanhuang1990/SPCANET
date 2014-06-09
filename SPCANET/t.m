for i=1:30*8  
    d=kron(reshape(1:300*300,[300,300]),reshape(1:300*300,[300,300])); 
    d=d+1;
    fprintf('%d',d(1,1));
end