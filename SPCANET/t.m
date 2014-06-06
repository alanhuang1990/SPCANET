for i=1:30*8  
    d=kron(reshape(1:64*64,[64,64]),reshape(1:64*64,[64,64])); 
    d=d+1;
    fprintf('%d',d(1,1));
end