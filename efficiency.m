function E = efficiency(s,n)
% E = efficiency(s,n)

%make the event matrix out of the event sequence
X = zeros(length(s),n);
temp = s;
for i=1:n
    X(:,i) = temp;
    temp = [0;temp(1:end-1)];
end

%calculate the efficiency
E = 1/trace(inv(X'*X));