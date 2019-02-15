function minDrum = selecteazaDrum(fereastraA, fereastraB, orientare)

[liniiFereastra, coloaneFereastra,~] = size(fereastraA);

auxMatrix = zeros(liniiFereastra, coloaneFereastra);

switch orientare
    case 'vertical'
        for i = 1:coloaneFereastra
            auxMatrix(1,i) = sum(( double(fereastraA(1,i,:)) - double(fereastraB(1,i,:)) ).^2);
        end
%construieste matrice cu distante
        for i = 2:liniiFereastra
            for j = 1 :coloaneFereastra
        
                if j == 1 %pixelul este localizat la marginea din stanga
                    [~, poz] = min([auxMatrix(i - 1,j), auxMatrix(i - 1, j + 1)]);
                    poz = poz - 1;
                elseif j == coloaneFereastra%pixelul este la marginea din dreapta
                    [~, poz] = min([auxMatrix(i - 1,j - 1), auxMatrix(i - 1, j )]);
                    poz = poz - 2;
                else
                    [~, poz] = min([auxMatrix(i - 1,j - 1), auxMatrix(i - 1, j ), auxMatrix(i - 1, j + 1)]);
                    poz = poz - 2;
                end
            auxMatrix(i, j) = sum((double(fereastraA(i,j,:)) - double(fereastraB(i,j,:))).^2) + auxMatrix(i - 1, j + poz); 
            end
        end

        minDrum = zeros(liniiFereastra, 2);

      
        [~, coloanaL] = min(auxMatrix(liniiFereastra, :));
        minDrum(liniiFereastra, :) = [liniiFereastra coloanaL];
        for i = liniiFereastra - 1: -1: 1
            if coloanaL == 1
                [~, poz] = min([auxMatrix(i, coloanaL), auxMatrix(i, coloanaL + 1)]);
                coloanaL = coloanaL + poz - 1;
            elseif coloanaL == coloaneFereastra
                [~, poz] = min([auxMatrix(i, coloanaL - 1), auxMatrix(i, coloanaL)]);
                coloanaL = coloanaL + poz - 2;
            else
                [~, poz] = min([auxMatrix(i, coloanaL - 1), auxMatrix(i, coloanaL), auxMatrix(i, coloanaL + 1)]);
                coloanaL = coloanaL + poz - 2;
            end
            minDrum(i, :) = [i, coloanaL];
        end
    case 'orizontal'
        
        fereastraA = permute(fereastraA,[2 1 3]); 
        fereastraB = permute(fereastraB,[2 1 3]);
        minDrum = transpose(selecteazaDrum(fereastraA, fereastraB, 'vertical'));
end
end

