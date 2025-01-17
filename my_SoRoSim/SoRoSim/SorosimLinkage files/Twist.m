%Class that assigns DoFs and Bases to link pieces and can calculate the
%twist given joint angles 
%Last modified by Anup Teejo Mathew 03.02.2022

classdef Twist < handle
    
    properties
        Bdof         %(6x1) array specifying the allowable DoFs of a soft piece. 1 if allowed 0 if not.
        Bodr         %(6x1) array specifying the order of allowed DoF (0: constant, 1: linear, 2: quadratic,...)
        B            %(6xdof) Base matrix calculated at lumped joints or ((6xnGauss)xdof) base matrices computed at every significant points of a soft division
        B_Z1         %Base calculated at first Zanna point (Xs+Z1*(delta(Xs)))
        B_Z2         %Base calculated at the second Zanna point (Xs+Z2*(delta(Xs)))
        xi_starfn    %Reference strain vector as a function of X
        xi_star      %(6x1) reference strain vector at the lumped joint or ((6xnGauss)x3) reference strain vectors computed at Gauss quadrature and Zannah collocation points
        dof          %Total degrees of freedom of the piece
    end
    
    methods
        
        function T = Twist(i,j,Xs,B)
            
            if nargin==3

                custombase(i,j);
                load('Base_properties.mat','Bdof','Bodr','xi_stars')
                T.Bdof   = Bdof;
                T.Bodr   = Bodr;
                dof      = sum(Bdof.*(Bodr+1));
                
                nGauss   = length(Xs);             %number of Gauss points for Lagrange model
                
                Z1       = 1/2-sqrt(3)/6;          %Zanna quadrature coefficient
                Z2       = 1/2+sqrt(3)/6;          %Zanna quadrature coefficient
                
                B        = zeros(nGauss*6,dof);
                B_Z1     = zeros(nGauss*6,dof);
                B_Z2     = zeros(nGauss*6,dof);
                
                for j=1:6
                    for k = 1:Bdof(j)*Bodr(j)+Bdof(j)
                        kk      = sum(Bdof(1:j-1).*Bodr(1:j-1))+sum(Bdof(1:j-1))+k;
                        B(j,kk) = (Xs(1))^(k-1);
                    end
                end
                for i=2:nGauss
                    for j=1:6
                        for k = 1:Bdof(j)*Bodr(j)+Bdof(j)
                            kk                 = sum(Bdof(1:j-1).*Bodr(1:j-1))+sum(Bdof(1:j-1))+k;
                            B(6*(i-1)+j,kk)    = (Xs(i))^(k-1);
                            B_Z1(6*(i-2)+j,kk) = (Xs(i-1)+Z1*(Xs(i)-Xs(i-1)))^(k-1);
                            B_Z2(6*(i-2)+j,kk) = (Xs(i-1)+Z2*(Xs(i)-Xs(i-1)))^(k-1);
                        end
                    end
                end
                
                T.B       = B;
                T.B_Z1    = B_Z1;
                T.B_Z2    = B_Z2;
                
                syms X;
                xi_stars1 = str2sym(xi_stars{1});
                xi_stars2 = str2sym(xi_stars{2});
                xi_stars3 = str2sym(xi_stars{3});
                xi_stars4 = str2sym(xi_stars{4});
                xi_stars5 = str2sym(xi_stars{5});
                xi_stars6 = str2sym(xi_stars{6});
                xi_stars  = [xi_stars1;xi_stars2;xi_stars3;xi_stars4;xi_stars5;xi_stars6];
                
                if any(has(xi_stars,X))
                    xi_starfn = matlabFunction(xi_stars);
                else 
                    xi_starfn = str2func(['@(X) [' num2str(double(xi_stars')) ']''']);
                end
                
                T.xi_starfn = xi_starfn;
                
                xi_star = zeros(6*nGauss,3);
                xi_star(1:6,1)     = xi_starfn(Xs(1)); %1
                for ii=2:nGauss
                    xi_star((ii-1)*6+1:ii*6,1)     = xi_starfn(Xs(ii)); %2 to nGauss
                    xi_star((ii-2)*6+1:(ii-1)*6,2) = xi_starfn(Xs(ii-1)+Z1*(Xs(ii)-Xs(ii-1))); %1 to nGauss-1
                    xi_star((ii-2)*6+1:(ii-1)*6,3) = xi_starfn(Xs(ii-1)+Z2*(Xs(ii)-Xs(ii-1))); %1 to nGauss-1
                end
                
                T.xi_star = xi_star;
                T.dof     = dof;
                
                
            elseif nargin==4
                
                T.B       = B;

            elseif nargin==0
                
                xi_starfn   = str2func('@(X) [0 0 0 1 0 0]''');
                T.B         = [];
                T.xi_starfn = xi_starfn;
                T.Bodr      = zeros(6,1);
                T.Bdof      = zeros(6,1);
                T.dof       = 0;
            end
            
        end
        %Changing nCLj:
        function set.Bdof(T, value)
            T.Bdof = value;
            T.Update();
        end
        function set.Bodr(T, value)
            T.Bodr = value;
            T.Update();
        end
        function Update(T)
            if isempty(T.dof)
                return
            end
            T.dof      = sum(T.Bdof.*(T.Bodr+1));

            nGauss   = size(T.B,1)/6;          %number of Gauss points for Lagrange model
            Xs       = GaussQuadrature(nGauss-2);
            
            Z1       = 1/2-sqrt(3)/6;          %Zanna quadrature coefficient
            Z2       = 1/2+sqrt(3)/6;          %Zanna quadrature coefficient

            T.B        = zeros(nGauss*6,T.dof);
            T.B_Z1     = zeros(nGauss*6,T.dof);
            T.B_Z2     = zeros(nGauss*6,T.dof);

            for j=1:6
                for k = 1:T.Bdof(j)*T.Bodr(j)+T.Bdof(j)
                    kk        = sum(T.Bdof(1:j-1).*T.Bodr(1:j-1))+sum(T.Bdof(1:j-1))+k;
                    T.B(j,kk) = (Xs(1))^(k-1);
                end
            end
            for i=2:nGauss
                for j=1:6
                    for k = 1:T.Bdof(j)*T.Bodr(j)+T.Bdof(j)
                        kk                   = sum(T.Bdof(1:j-1).*T.Bodr(1:j-1))+sum(T.Bdof(1:j-1))+k;
                        T.B(6*(i-1)+j,kk)    = (Xs(i))^(k-1);
                        T.B_Z1(6*(i-2)+j,kk) = (Xs(i-1)+Z1*(Xs(i)-Xs(i-1)))^(k-1);
                        T.B_Z2(6*(i-2)+j,kk) = (Xs(i-1)+Z2*(Xs(i)-Xs(i-1)))^(k-1);
                    end
                end
            end
        end
        
        function set.xi_starfn(T, value)
            T.xi_starfn = value;
            T.Updatexi_star();
        end
        function Updatexi_star(T)
            if isempty(T.dof)
                return
            end
            nGauss   = size(T.B,1)/6;            %number of Gauss points for Lagrange model
            Xs       = GaussQuadrature(nGauss-2);
            Z1       = 1/2-sqrt(3)/6;          %Zanna quadrature coefficient
            Z2       = 1/2+sqrt(3)/6;          %Zanna quadrature coefficient
            
            T.xi_star        = zeros(6*nGauss,3);
            T.xi_star(1:6,1) = T.xi_starfn(Xs(1)); %1
            for ii=2:nGauss
                T.xi_star((ii-1)*6+1:ii*6,1)     = T.xi_starfn(Xs(ii)); %2 to nGauss
                T.xi_star((ii-2)*6+1:(ii-1)*6,2) = T.xi_starfn(Xs(ii-1)+Z1*(Xs(ii)-Xs(ii-1))); %1 to nGauss-1
                T.xi_star((ii-2)*6+1:(ii-1)*6,3) = T.xi_starfn(Xs(ii-1)+Z2*(Xs(ii)-Xs(ii-1))); %1 to nGauss-1
            end
        end
    end
    
end

