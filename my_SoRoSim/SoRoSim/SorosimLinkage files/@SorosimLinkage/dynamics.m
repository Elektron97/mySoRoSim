%Function for the dynamic simulation of the linkage
%Last modified by Anup Teejo Mathew 23/05/2021
function [t,qqd] = dynamics(Tr,odetype,dt)

nact  = Tr.nact;
uqt   = cell(nact,1);
ndof  = Tr.ndof;

if Tr.Actuated
    
    n_jact             = Tr.n_jact;
    i_jactq            = Tr.i_jactq;
    WrenchControlled   = Tr.WrenchControlled;
    
    if ~Tr.CAS
        
        uqt(1:n_jact) = InputJointUQt(Tr);

        for i=n_jact+1:nact

                prompt = ['Enter the strength (N) of the soft actuator ',num2str(i-Tr.n_jact),' as a function of t (time)'...
                          '\n[Examples: -10-5*t, -50*t+(50*t-50)*heaviside(t-1), 50*sin(2*pi*t)]: '];
                funstr = input(prompt, 's');
                uqt{i} = str2func( ['@(t) ' funstr ] );

        end
    end
    
end


%initial guess definition: reference configuration
q0                 = zeros(1,ndof);
ndof               = Tr.ndof;
qd0                = zeros(1,ndof);

if Tr.Actuated
    i_qControlled      = i_jactq.*~WrenchControlled;
    i_qControlled      = i_qControlled(i_qControlled~=0);
    q0(i_qControlled)  = [];
    qd0(i_qControlled) = [];
end

prompt           = {'Enter the value of q_{0}','qdot_{0}','Simulation time (s)'};
dlgtitle         = 'Initial condition';
definput         = {num2str(q0),num2str(qd0),'5'};
opts.Interpreter = 'tex';
answer           = inputdlg(prompt,dlgtitle,[1 75],definput,opts);

q0   = str2num(answer{1})';
qd0  = str2num(answer{2})';
tmax = str2num(answer{3});

if Tr.Actuated
    q0_pass          = zeros(ndof,1);
    qd0_pass         = zeros(ndof,1);
    i                = 1:ndof;
    i(i_qControlled) = [];
    q0_pass(i)       = q0;
    qd0_pass(i)      = qd0;
    q0               = q0_pass;
    qd0              = qd0_pass;

    for i=1:n_jact
        if ~WrenchControlled(i)
            q0(i_jactq(i))   = uqt{i}{1}(0);
            qd0(i_jactq(i))  = uqt{i}{2}(0);
        end
    end
end

Tr.q_scale = find_q_scale(Tr);

qqd0 = [q0./Tr.q_scale ; qd0./Tr.q_scale];


if nargin==1
    odetype='ode45';
end

profile on

switch odetype
    case 'ode45'
        answer = questdlg('Display graphical output during simulation (slow, works only for long simulations)?','Grapical Output','Yes','No','No');
        switch answer
            case 'Yes'
                Show = true;
            case 'No'
                Show = false;
        end
        options = odeset('OutputFcn',@(t,y,flag)odeprogress(t,y,flag,Tr,Show),'RelTol',1e-3,'AbsTol',1e-6);% default values'RelTol',1e-3,'AbsTol',1e-6
        tic
        [t,qqd] = ode45(@(t,qqd) Tr.derivatives(t,qqd,uqt),[0 tmax],qqd0,options);
        toc
    case 'ode1'
        if nargin==2
            dt=0.001;
        end
        tic
        qqd = ode1(@(t,qqd) Tr.derivatives(t,qqd,uqt),0:dt:tmax,qqd0);
        toc
        t=0:dt:tmax;
end

profile off

qqd = qqd.*repmat(Tr.q_scale',length(t),2);
save('DynamicsSolution.mat','t','qqd');

answer = questdlg('Generate output video of the simulation?','Grapical Output', ...
	'Yes','No','Yes');

if strcmp('Yes',answer)
    plotqqd(Tr,t,qqd);
end


end

