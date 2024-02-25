function B = B_CustomIndependent(X,varargin)
%To add a different custom base, make a file similar to this and change the file name of function handle in the corresponding Twist
%column of B should be linearly independent with others
%Change SorosimTwist.Type = 'Custom Independent'

% X varies from 0 to 1

%Two FEM Quad Elements with constant torsion and constant elongation

nele = 2;

dof = 1+2*5+1;

B   = zeros(6,dof);
B(:,1)   = [1;0;0;0;0;0];%constant torsion
B(:,end) = [0;0;0;1;0;0];%constant elongation

k = 2;

Bdof = [0 1 1 0 0 0]'; %FEM dof

for i=1:6
    w = 1/nele;
    a = 0;

    for j=1:Bdof(i)*nele
        b = a+w;
        if X>=a&&X<=b
            Xc = (X-a)/(b-a);
            B(i,k)   =  2*(Xc-1/2)*(Xc-1);
            B(i,k+1) = -4*Xc*(Xc-1);
            B(i,k+2) =  2*Xc*(Xc-1/2);
        end
        k = k+2;
        a = a+w;
    end

    k = k+Bdof(i);
end

end