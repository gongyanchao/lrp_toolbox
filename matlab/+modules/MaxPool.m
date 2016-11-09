classdef MaxPool < modules.Module
    % @author: Sebastian Lapuschkin
    % @author: Gregoire Montavon
    % @maintainer: Sebastian Lapuschkin
    % @contact: sebastian.lapuschkin@hhi.fraunhofer.de
    % @date: 09.11.2016
    % @version: 1.0
    % @copyright: Copyright (c) 2016, Sebastian Lapuschkin, Alexander Binder, Gregoire Montavon, Klaus-Robert Mueller
    % @license : BSD-2-Clause
    %
    % Rectification Layer

    properties
        %temporary variables
        Y
        X
    end

    methods
        function obj = MaxPool(pool,stride)
            obj = obj@modules.Module();

            if nargin < 2 || (exist('stride','var') && isempty(stride))
              obj.stride = [2,2];
            end
            if nargin < 1 || (exist('pool','var') && isempty(pool))
               obj.pool = [2,2];
            end
        end

        function Y = forward(obj,X)
            obj.X = X;
            [N,H,W,D]= size(X);
            
            hpool = obj.pool(1);        wpool = obj.pool(2);
            hstride = obj.stride(1);    wstride = obj.stride(2);
            
            %assume the given pooling and stride parameters are carefully
            %chosen
            Hout = (H - hpool)/hstride + 1;
            Wout = (W - wpool)/wstride + 1;
            
            %initialize output
            obj.Y = zeros(N,Hout,Wout,D);
            for i = 1:Hout
               for j = 1:Wout
                  obj.Y(:,i,j,:) = max(max(X(:,(i-1)*hstride+1:(i-1)*hstride+hpool,(j-1)*wstride+1:(j-1)*wstride+wpool,:),[],2),[],3);
               end
            end
            Y = obj.Y; %'return'
        end
        
        function DX = backward(obj,DY)
            [N,H,W,D] = size(obj.X);

            hpool = obj.pool(1);        wpool = obj.pool(2);
            hstride = obj.stride(1);    wstride = obj.stride(2);

            %assume the given pooling and stride parameters are carefully
            %chosen
            Hout = (H - hpool)/hstride + 1;
            Wout = (W - wpool)/wstride + 1;
            
            %distribute the gradient (1 * DY) towards all contributing
            %inputs evenly
            DX = zeros(N,H,D,W);
            for i = 1:Hout
                for j = 1:Wout
                    x = obj.X(: , (i-1)*hstride+1:(i-1)*hstride+hpool , (j-1)*wstride+1:(j-1)*wstride+wpool , :);
                    y = repmat(obj.Y(:,i,j,:),[1 hpool wpool 1]);
                    
                    dy = repmat(DY(:,i,j,:),[1 hpool wpool 1]);
                    dx = DX(: , (i-1)*hstride+1:(i-1)*hstride+hpool , (j-1)*wstride+1:(j-1)*wstride+wpool , :);
                         
                    DX(: , (i-1)*hstride+1:(i-1)*hstride+hpool , (j-1)*wstride+1:(j-1)*wstride+wpool , :) = dx + dy .* (x == y);
                end
            end     
        end
        
        function clean(obj)
           obj.X = [];
           obj.Y = [];
        end
        
        function Rx = lrp(obj,R,varargin)
            % LRP according to Eq(56) in DOI: 10.1371/journal.pone.0130140
            [N,H,W,D] = size(obj.X);

            hpool = obj.pool(1);        wpool = obj.pool(2);
            hstride = obj.stride(1);    wstride = obj.stride(2);

            %assume the given pooling and stride parameters are carefully
            %chosen
            Hout = (H - hpool)/hstride + 1;
            Wout = (W - wpool)/wstride + 1;
            
            Rx = zeros(N,H,D,W);
            for i = 1:Hout
                for j = 1:Wout
                    x = obj.X(: , (i-1)*hstride+1:(i-1)*hstride+hpool , (j-1)*wstride+1:(j-1)*wstride+wpool , :);
                    y = repmat(obj.Y(:,i,j,:),[1 hpool wpool 1]);
                    
                    Z = x == y;
                    Zs = sum(sum(Z,2),3);

                    rr = repmat(R(:,i,j,:),[1,hpool,wpool,1]);
                    zz = Z ./ repmat(Zs,[1,hpool,wpool,1]);
                    rx = Rx(: , (i-1)*hstride+1:(i-1)*hstride+hpool , (j-1)*wstride+1:(j-1)*wstride+wpool , :);
                    
                    Rx(: , (i-1)*hstride+1:(i-1)*hstride+hpool , (j-1)*wstride+1:(j-1)*wstride+wpool , :) = rx + rr .* zz;
                end
            end
        end
    end
end