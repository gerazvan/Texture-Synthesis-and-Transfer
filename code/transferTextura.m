function imgSintetizata = transferTextura(parametri)

imgModel = imread('../data/eminescu.jpg');
if size(parametri.texturaInitiala,3) == 1
imgModel = rgb2gray(imgModel);
end
nrBlocuri =  parametri.nrBlocuri;

[inaltimeTexturaInitiala, latimeTexturaInitiala, nrCanale] = ...
    size(parametri.texturaInitiala);

[H2, W2] = size(imgModel(:, :, 1));

overlap =  parametri.portiuneSuprapunere;

imgSintetizata = uint8(zeros(H2,W2,nrCanale));

N = 3;
for k = 1 : N
    
    dimBloc =  floor(parametri.dimensiuneBloc / (2 ^ (k - 1)));
    blocuri = uint8(zeros(dimBloc, dimBloc, nrCanale, nrBlocuri));
    
    y = randi(inaltimeTexturaInitiala - dimBloc + 1, nrBlocuri, 1);
    x = randi(latimeTexturaInitiala - dimBloc + 1, nrBlocuri, 1);
    
    
    for i = 1:nrBlocuri
        blocuri(:,:,:,i) =  parametri.texturaInitiala(y(i):y(i) + dimBloc - 1, ...
            x(i): x(i) + dimBloc - 1, : );
    end
    
    
    
    alpha = 0.8 * (k - 1) / (N - 1) + 0.1;
    suprapunere = ceil(overlap * dimBloc) + 1;
    nrBlocuriX = ceil((W2 - dimBloc)/(dimBloc - suprapunere)) + 1;
    nrBlocuriY = ceil((H2 - dimBloc)/(dimBloc - suprapunere)) + 1;
    dimX = (nrBlocuriX - 1) * (dimBloc - suprapunere) + dimBloc;
    dimY = (nrBlocuriY - 1) * (dimBloc - suprapunere) + dimBloc;
    dimC = nrCanale;
    imgSintetizataMaiMare = uint8(zeros(dimY, dimX, dimC));
    imgModel = imresize(imgModel, [size(imgSintetizataMaiMare, 1) size(imgSintetizataMaiMare,2)]);
    
    if k == 1     
        imgSintetizataAnterior = uint8(zeros(dimY,dimX,dimC));
    else
        imgSintetizataAnterior = imresize(imgSintetizataAnterior, [size(imgSintetizataMaiMare, 1) size(imgSintetizataMaiMare,2)]);
    end
    
    for x = 1:nrBlocuriX
        for y = 1:nrBlocuriY
            
            xMinFereastra = (x - 1) * (dimBloc - suprapunere) + 1;
            yMinFereastra = (y - 1) * (dimBloc - suprapunere) + 1;
            xMaxFereastra = xMinFereastra + dimBloc - 1;
            yMaxFereastra = yMinFereastra + dimBloc - 1;
            
            fereastra = imgSintetizataMaiMare(yMinFereastra:yMaxFereastra, xMinFereastra:xMaxFereastra,:);
            fereastraModel = imgModel(yMinFereastra:yMaxFereastra, xMinFereastra:xMaxFereastra,:);
            if k > 1
                fereastraAnterior = imgSintetizataAnterior(yMinFereastra:yMaxFereastra, xMinFereastra:xMaxFereastra,:);
            end
            
            d = zeros(1, nrBlocuri);
            eroareCoresp = zeros(1, nrBlocuri);
            erori = zeros(1, nrBlocuri);
            
            for i = 1:nrBlocuri
                if x > 1
                    A = fereastra(:,1:suprapunere,:);
                    B = blocuri(:,:,:,i);
                    B = B(:,1:suprapunere,:);
                    d(i) = sum(( double(A(:)) - double(B(:)) ).^2 );
                end
                if y > 1
                    A = fereastra(1:suprapunere, :, :);
                    B = blocuri(:, :, :, i);
                    B = B(1:suprapunere, :, :);
                    dist = sum(( double(A(:)) - double(B(:)) ).^2 );
                    if x > 1
                        d(i)=d(i)+dist;
                        A = fereastra(1:suprapunere,1:suprapunere,:);
                        B = blocuri(:,:,:,i);
                        B = B(1:suprapunere,1:suprapunere,:);
                        dist2 = sum(( double(A(:)) - double(B(:)) ).^2 );
                        d(i) = d(i)-dist2;
                    else
                        d(i) = dist;
                    end
                end
                B = blocuri(:,:,:,i);
                eroareCoresp(i) = sum(( double(B(:)) - double(fereastraModel(:)) ).^2 );
                
                if k == 1
                    erori(i) = alpha * d(i) + (1 - alpha) * eroareCoresp(i);
                else
                    eroareSintezaAnterioara = sum(( double(B(:)) - double(fereastraAnterior(:)) ).^2 );
                    erori(i) = alpha * (d(i) + eroareSintezaAnterioara) + (1 - alpha) * eroareCoresp(i);
                end
                
                
            end
            
            eMin = min(erori);
            pozitiiMinime = find(erori <= (1+parametri.eroareTolerata) * eMin);
            pozAleatoare = randperm(numel(pozitiiMinime));
            pozAleatoare = pozAleatoare(1);
            
            
            drumOriz = zeros(2,size(fereastra,2));
            drumVert = zeros(size(fereastra,1), 2);
            %daca se suprapune pe orizontala
            %calculez drum vertical
            if x > 1
                A = fereastra(:,1:suprapunere,:);
                B = blocuri(:,:,:,pozitiiMinime(pozAleatoare));
                B = B(:,1:suprapunere,:);
                drumVert = selecteazaDrum(A,B,'vertical');
            end
            %daca se suprapune pe verticala
            %calculez drum orizontal
            if y > 1
                A = fereastra(1:suprapunere, :, :);
                B = blocuri(:, :, :, pozitiiMinime(pozAleatoare));
                B = B(1:suprapunere, :, :);
                drumOriz = selecteazaDrum(A, B, 'orizontal');
            end
            
            
            for i = yMinFereastra:yMaxFereastra
                for j = xMinFereastra:xMaxFereastra
                    %daca x > 1 y > 1 iau in calcul drum vertical +
                    %orizontal. x > 1 iau in considerare drum vertical
                    % y > 1 iau in considerare drum orizontal
                    %unde nu pun bloc inseamna ca exista deja ceva in
                    %imgSintetizataMaiMare
                    if x > 1 && y > 1
                        if i - yMinFereastra + 1 >= drumOriz(2, j - xMinFereastra + 1) && ...
                                j - xMinFereastra + 1 >= drumVert(i - yMinFereastra + 1 ,2)
                            imgSintetizataMaiMare(i,j,:) = blocuri(i - yMinFereastra + 1,j - xMinFereastra + 1,:,pozitiiMinime(pozAleatoare));
                        end
                    elseif x > 1
                        if j - xMinFereastra + 1 >= drumVert(i - yMinFereastra + 1 ,2)
                            imgSintetizataMaiMare(i,j,:) = blocuri(i - yMinFereastra + 1,j - xMinFereastra + 1,:,pozitiiMinime(pozAleatoare));
                            
                        end
                    elseif y > 1
                        if i - yMinFereastra + 1 >= drumOriz(2, j - xMinFereastra + 1)
                            imgSintetizataMaiMare(i,j,:) = blocuri(i - yMinFereastra + 1,j - xMinFereastra + 1,:,pozitiiMinime(pozAleatoare));
                            
                        end
                    else
                        imgSintetizataMaiMare(i,j,:) = blocuri(i - yMinFereastra + 1,j - xMinFereastra + 1,:,pozitiiMinime(pozAleatoare));
                    end
                    
                end
            end
            
        end
    end
    
    imgSintetizataAnterior = imgSintetizataMaiMare;
    imgSintetizata = imgSintetizataMaiMare(1:H2,1:W2,:);
    figure, imshow(parametri.texturaInitiala)
    figure, imshow(imgSintetizata);
    title(['Rezultat obtinut pentru transferarea texturii:' num2str(k)]);
end

end