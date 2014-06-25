function fhy = GetIGO(img_in)

[gx,gy] = gradient(img_in);

fhy = atan(gy./(gx+eps));

%correction
cor = find(gy<0 & gx<0);
fhy(cor) = fhy(cor)+pi;
cor = find(gy>0 & gx<0);
fhy(cor) = fhy(cor)+pi;
%cor = find(fhy<0);
%fhy(cor) = fhy(cor)+pi*2;

fhy = exp(1i*fhy);
end