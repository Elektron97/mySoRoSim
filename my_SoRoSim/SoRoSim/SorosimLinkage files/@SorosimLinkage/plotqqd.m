%Function for the plot of dynamic simulation
%Last modified by Anup Teejo Mathew - 25/05/2021
function plotqqd(Tr,t,qqd)
close all

PlottingParameters = Tr.PlotParameters;

N         = Tr.N;
g_ini     = Tr.g_ini;
iLpre     = Tr.iLpre;

tic
tmax        = max(t);
v           = VideoWriter('.\Dynamics');
FrameRate   = PlottingParameters.FrameRateValue;
v.FrameRate = FrameRate;
open(v);

hfig      = figure('units','normalized','outerposition',[0 0 1 1]);
set(gca,'CameraPosition',PlottingParameters.CameraPosition,...
        'CameraTarget',PlottingParameters.CameraTarget,...
        'CameraUpVector',PlottingParameters.CameraUpVector,...
        'FontSize',18);
    
if PlottingParameters.Light
    camlight(PlottingParameters.Az_light,PlottingParameters.El_light)
end
    view(-90,90); % 2D View
axis equal
grid on
hold on
xlabel('X (m)')
ylabel('Y (m)')
zlabel('Z (m)') 
axis([PlottingParameters.X_lim PlottingParameters.Y_lim PlottingParameters.Z_lim]);
drawnow
drawnow

for tt=0:1/FrameRate:tmax

    delete(findobj('type', 'patch'));
    
    title(strcat('t= ',num2str(tt)))
   
    qqdtt = interp1(t,qqd,tt);
    q     = qqdtt(1:Tr.ndof)';
    
    dof_start = 1;
    g_Ltip    = repmat(eye(4),N,1);
    
    for i=1:N % number of links
        
        if iLpre(i)>0
            g_here=g_Ltip((iLpre(i)-1)*4+1:iLpre(i)*4,:)*g_ini((i-1)*4+1:i*4,:);
        else
            g_here=g_ini((i-1)*4+1:i*4,:);
        end
        
        %joint
        dof_here   = Tr.CVTwists{i}(1).dof;
        q_here     = q(dof_start:dof_start+dof_here-1);
        B_here     = Tr.CVTwists{i}(1).B;
        xi_star    = Tr.CVTwists{i}(1).xi_star;

        if dof_here==0 %fixed joint (N)
            g_joint    = eye(4);
        else
            if Tr.VLinks(Tr.LinkIndex(i)).jointtype=='U' %special case for universal joint. Considered as 2 revolute joints
                % first revolute joint
                xi         = B_here(:,1)*q_here(1)+xi_star;
                g_joint    = joint_expmap(xi);
                g_here     = g_here*g_joint;

                % second revolute joint
                xi         = B_here(:,2)*q_here(2)+xi_star;
                g_joint    = joint_expmap(xi);
            else
                xi         = B_here*q_here+xi_star;
                g_joint    = joint_expmap(xi);
            end
        end
        g_here     = g_here*g_joint;
        
        n_r   = Tr.VLinks(Tr.LinkIndex(i)).n_r;
        if Tr.VLinks(Tr.LinkIndex(i)).CS=='R'
            n_r=5;
        end
        n_l   = Tr.VLinks(Tr.LinkIndex(i)).n_l;
        color = Tr.VLinks(Tr.LinkIndex(i)).color;
        
        if Tr.VLinks(Tr.LinkIndex(i)).linktype=='r'
            L          = Tr.VLinks(Tr.LinkIndex(i)).L;
            gi         = Tr.VLinks(Tr.LinkIndex(i)).gi;
            g_here     = g_here*gi;
            Xr         = linspace(0,L,n_l);
            g_hereR    = g_here*[eye(3) [-Tr.VLinks(Tr.LinkIndex(i)).gi(1,4);0;0];0 0 0 1]; 
            dx         = Xr(2)-Xr(1);
            
            Xpatch  = zeros(n_r,n_l);
            Ypatch  = zeros(n_r,n_l);
            Zpatch  = zeros(n_r,n_l);
            i_patch = 1;

            if Tr.VLinks(Tr.LinkIndex(i)).CS=='C'

                r_fn  = Tr.VLinks(Tr.LinkIndex(i)).r;
                r     = r_fn(0);
                theta = linspace(0,2*pi,n_r);
                x     = zeros(1,n_r);
                y     = r*sin(theta);
                z     = r*cos(theta);
                pos   = [x;y;z;ones(1,n_r)];

            elseif Tr.VLinks(Tr.LinkIndex(i)).CS=='R'

                h_fn  = Tr.VLinks(Tr.LinkIndex(i)).h;
                w_fn  = Tr.VLinks(Tr.LinkIndex(i)).w;
                h     = h_fn(0);
                w     = w_fn(0);
                x     = [0 0 0 0 0];
                y     = [h/2 -h/2 -h/2 h/2 h/2];
                z     = [w/2 w/2 -w/2 -w/2 w/2];
                pos   = [x;y;z;ones(1,5)];
                
            elseif Tr.VLinks(Tr.LinkIndex(i)).CS=='E'

                a_fn  = Tr.VLinks(Tr.LinkIndex(i)).a;
                b_fn  = Tr.VLinks(Tr.LinkIndex(i)).b;
                a     = a_fn(0);
                b     = b_fn(0);
                theta = linspace(0,2*pi,n_r);
                x     = zeros(1,n_r);
                y     = a*sin(theta);
                z     = b*cos(theta);
                pos   = [x;y;z;ones(1,n_r)];
            end

            pos_here = g_hereR*pos;
            x_here   = pos_here(1,:);
            y_here   = pos_here(2,:);
            z_here   = pos_here(3,:);

            Xpatch(:,i_patch) = x_here';
            Ypatch(:,i_patch) = y_here';
            Zpatch(:,i_patch) = z_here';
            i_patch           = i_patch+1;

            x_pre    = x_here;
            y_pre    = y_here;
            z_pre    = z_here;
            
            for ii=2:n_l
                
                if Tr.VLinks(Tr.LinkIndex(i)).CS=='C'

                    r     = r_fn(Xr(ii)/L);
                    theta = linspace(0,2*pi,n_r);
                    x     = zeros(1,n_r);
                    y     = r*sin(theta);
                    z     = r*cos(theta);
                    pos   = [x;y;z;ones(1,n_r)];
                    
                elseif Tr.VLinks(Tr.LinkIndex(i)).CS=='R'

                    h     = h_fn(Xr(ii)/L);
                    w     = w_fn(Xr(ii)/L);
                    x     = [0 0 0 0 0];
                    y     = [h/2 -h/2 -h/2 h/2 h/2];
                    z     = [w/2 w/2 -w/2 -w/2 w/2];
                    pos   = [x;y;z;ones(1,5)];
                    
                elseif Tr.VLinks(Tr.LinkIndex(i)).CS=='E'

                    a     = a_fn(Xr(ii)/L);
                    b     = b_fn(Xr(ii)/L);
                    theta = linspace(0,2*pi,n_r);
                    x     = zeros(1,n_r);
                    y     = a*sin(theta);
                    z     = b*cos(theta);
                    pos   = [x;y;z;ones(1,n_r)];
                end
                
                g_hereR  = g_hereR*[eye(3) [dx;0;0];0 0 0 1];
                pos_here = g_hereR*pos;
                x_here   = pos_here(1,:);
                y_here   = pos_here(2,:);
                z_here   = pos_here(3,:);

                %Plotting rigid link
                for jj=1:n_r-1

                    Xpatch(1:5,i_patch)   = [x_pre(jj) x_here(jj) x_here(jj+1) x_pre(jj+1) x_pre(jj)]';
                    Xpatch(6:end,i_patch) = x_pre(jj)*ones(n_r-5,1);
                    Ypatch(1:5,i_patch)   = [y_pre(jj) y_here(jj) y_here(jj+1) y_pre(jj+1) y_pre(jj)]';
                    Ypatch(6:end,i_patch) = y_pre(jj)*ones(n_r-5,1);
                    Zpatch(1:5,i_patch)   = [z_pre(jj) z_here(jj) z_here(jj+1) z_pre(jj+1) z_pre(jj)]';
                    Zpatch(6:end,i_patch) = z_pre(jj)*ones(n_r-5,1);
                    i_patch = i_patch+1;

                end

                x_pre    = x_here;
                y_pre    = y_here;
                z_pre    = z_here;

            end

            Xpatch(:,i_patch) = x_here';
            Ypatch(:,i_patch) = y_here';
            Zpatch(:,i_patch) = z_here';

            gf     = Tr.VLinks(Tr.LinkIndex(i)).gf;
            g_here = g_here*gf;
            
            patch(Xpatch,Ypatch,Zpatch,color,'EdgeColor','none');

        end
        
        
        dof_start = dof_start+dof_here;
        
            %=============================================================================
        for j=1:(Tr.VLinks(Tr.LinkIndex(i)).npie)-1 % for each piece
            
            dof_here   = Tr.CVTwists{i}(j+1).dof;
            q_here     = q(dof_start:dof_start+dof_here-1);
            xi_starfn  = Tr.CVTwists{i}(j+1).xi_starfn;
            gi         = Tr.VLinks(Tr.LinkIndex(i)).gi{j};
            Bdof       = Tr.CVTwists{i}(j+1).Bdof;
            Bodr       = Tr.CVTwists{i}(j+1).Bodr;
            lpf        = Tr.VLinks(Tr.LinkIndex(i)).lp{j};
            g_here     = g_here*gi;
               
            Xs          = linspace(0,lpf,n_l);
            color       = Tr.VLinks(Tr.LinkIndex(i)).color;
            H           = Xs(2)-Xs(1);
            Z1          = (1/2-sqrt(3)/6)*H;          % Zanna quadrature coefficient
            Z2          = (1/2+sqrt(3)/6)*H;          % Zanna quadrature coefficient
            B_Z1here    = zeros(6,dof_here);
            B_Z2here    = zeros(6,dof_here);

            Xpatch  = zeros(n_r,n_l);
            Ypatch  = zeros(n_r,n_l);
            Zpatch  = zeros(n_r,n_l);
            i_patch = 1;
            
            if Tr.VLinks(Tr.LinkIndex(i)).CS=='C'
                
                r_fn  = Tr.VLinks(Tr.LinkIndex(i)).r{j};
                r     = r_fn(0);
                theta = linspace(0,2*pi,n_r);
                x     = zeros(1,n_r);
                y     = r*sin(theta);
                z     = r*cos(theta);
                pos   = [x;y;z;ones(1,n_r)];
            elseif Tr.VLinks(Tr.LinkIndex(i)).CS=='R'
                h_fn = Tr.VLinks(Tr.LinkIndex(i)).h{j};
                w_fn = Tr.VLinks(Tr.LinkIndex(i)).w{j};
                h    = h_fn(0);
                w    = w_fn(0);
                x    = [0 0 0 0 0];
                y    = [h/2 -h/2 -h/2 h/2 h/2];
                z    = [w/2 w/2 -w/2 -w/2 w/2];
                pos  = [x;y;z;ones(1,5)];
                
            elseif Tr.VLinks(Tr.LinkIndex(i)).CS=='E'
                a_fn  = Tr.VLinks(Tr.LinkIndex(i)).a{j};
                b_fn  = Tr.VLinks(Tr.LinkIndex(i)).b{j};
                a     = a_fn(0);
                b     = b_fn(0);
                theta = linspace(0,2*pi,n_r);
                x     = zeros(1,n_r);
                y     = a*sin(theta);
                z     = b*cos(theta);
                pos   = [x;y;z;ones(1,n_r)];
            end

            pos_here = g_here*pos;
            x_here   = pos_here(1,:);
            y_here   = pos_here(2,:);
            z_here   = pos_here(3,:);

            Xpatch(:,i_patch) = x_here';
            Ypatch(:,i_patch) = y_here';
            Zpatch(:,i_patch) = z_here';
            i_patch           = i_patch+1;

            x_pre = x_here;
            y_pre = y_here;
            z_pre = z_here;
            
            for ii=1:n_l-1
                
                if Tr.VLinks(Tr.LinkIndex(i)).CS=='C'
                    r     = r_fn(Xs(ii)/lpf);
                    theta = linspace(0,2*pi,n_r);
                    x     = zeros(1,n_r);
                    y     = r*sin(theta);
                    z     = r*cos(theta);
                    pos   = [x;y;z;ones(1,n_r)];
                elseif Tr.VLinks(Tr.LinkIndex(i)).CS=='R'

                    h   = h_fn(Xs(ii)/lpf);
                    w   = w_fn(Xs(ii)/lpf);
                    x   = [0 0 0 0 0];
                    y   = [h/2 -h/2 -h/2 h/2 h/2];
                    z   = [w/2 w/2 -w/2 -w/2 w/2];
                    pos = [x;y;z;ones(1,5)];
                elseif Tr.VLinks(Tr.LinkIndex(i)).CS=='E'

                    a     = a_fn(Xs(ii)/lpf);
                    b     = b_fn(Xs(ii)/lpf);
                    theta = linspace(0,2*pi,n_r);
                    x     = zeros(1,n_r);
                    y     = a*sin(theta);
                    z     = b*cos(theta);
                    pos   = [x;y;z;ones(1,n_r)];
                end
                
                x    = Xs(ii);
                x_Z1 = x+Z1;
                x_Z2 = x+Z2;
                
                for jj=1:6
                    for k=1:Bdof(jj)*Bodr(jj)+Bdof(jj)
                        kk              = sum(Bdof(1:jj-1).*Bodr(1:jj-1))+sum(Bdof(1:jj-1))+k;
                        B_Z1here(jj,kk) = x_Z1^(k-1);
                        B_Z2here(jj,kk) = x_Z2^(k-1);
                    end
                end
                

                if ~isempty(q_here)
                    xi_Z1here  = B_Z1here*q_here+xi_starfn(x_Z1/lpf);
                    xi_Z2here  = B_Z2here*q_here+xi_starfn(x_Z2/lpf);
                else
                    xi_Z1here  = xi_starfn(x_Z1/lpf);
                    xi_Z2here  = xi_starfn(x_Z2/lpf);
                end
                
                Gamma_here    = (H/2)*(xi_Z1here+xi_Z2here)+...
                                ((sqrt(3)*H^2)/12)*dinamico_adj(xi_Z1here)*xi_Z2here;
                k_here        = Gamma_here(1:3);
                theta_here    = norm(k_here);
                gh            = variable_expmap(theta_here,Gamma_here);
                g_here        = g_here*gh;

                pos_here = g_here*pos;
                x_here   = pos_here(1,:);
                y_here   = pos_here(2,:);
                z_here   = pos_here(3,:);


                for jj=1:n_r-1

                    Xpatch(1:5,i_patch)   = [x_pre(jj) x_here(jj) x_here(jj+1) x_pre(jj+1) x_pre(jj)]';
                    Xpatch(6:end,i_patch) = x_pre(jj)*ones(n_r-5,1);
                    Ypatch(1:5,i_patch)   = [y_pre(jj) y_here(jj) y_here(jj+1) y_pre(jj+1) y_pre(jj)]';
                    Ypatch(6:end,i_patch) = y_pre(jj)*ones(n_r-5,1);
                    Zpatch(1:5,i_patch)   = [z_pre(jj) z_here(jj) z_here(jj+1) z_pre(jj+1) z_pre(jj)]';
                    Zpatch(6:end,i_patch) = z_pre(jj)*ones(n_r-5,1);
                    i_patch = i_patch+1;

                end
                
                x_pre = x_here;
                y_pre = y_here;
                z_pre = z_here;
                
            end

            Xpatch(:,i_patch) = x_here';
            Ypatch(:,i_patch) = y_here';
            Zpatch(:,i_patch) = z_here';

            patch(Xpatch,Ypatch,Zpatch,color,'EdgeColor','none');
           
            %updating g, Jacobian, Jacobian_dot and eta at X=L
            gf     = Tr.VLinks(Tr.LinkIndex(i)).gf{j};
            g_here = g_here*gf;
            
            dof_start = dof_start+dof_here;
            
        end
        g_Ltip((i-1)*4+1:i*4,:) = g_here;

    end
    
    frame = getframe(gcf);
    writeVideo(v,frame);
end

close(v);

answer = questdlg('Play output video in MATLAB?','Grapical Output', ...
	'Yes','No','Yes');

if strcmp('Yes',answer)
    implay('.\Dynamics.avi')
end
