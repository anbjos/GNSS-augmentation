# Julia implementation of https://en.wikipedia.org/wiki/Kalman_filter

using LinearAlgebra
using Random
using Distributions

eye(n)=Matrix{Float64}(I,n,n)
Gaussian(R)=MvNormal(zeros(size(R,1)),R)
negligible=floatmin(Float64)

Δt=0.1                  # timestep

F=[1 Δt; 0  1]          # State-transition model nxn
Q=negligible*eye(2)     # System noise is negligible nxn
W=Gaussian(Q)           # System noise random variable nxn
B=zeros(2,2)            # Control input model n x length(u)

H=[1 0]                 # Observation model mxn
R=[1]                   # Measurement covariance matrix mxm
V=Gaussian(R)           # Observation noise random variable mxm

# A priori knowledge (k=0)
x=[0.; 1.;;]            # True position and velocity nx1
x̂=[0.;0.;;]               # Estimated position and velocity nx1
P=eye(2)                # x̂ Covariance matrix nxn

for k in 1:100
    # System
    u=[0;0;;]           # Control vector free x 1
    w=rand(W)           # System noise nx1
    x=F*x+w             # x state update one timestep nx1
    v=rand(V)           # Measurement noise mx1
    z=H*x+v             # Measurement mx1

    # Prediction
    x̂=F*x̂+B*u         # Prediction of x nx1
    P=F*P*F'+Q          # covariance of x̂

    # Update
    y=z-H*x̂            # innovation mx1
    S=H*P*H'+R          # Innovation covariance

    # Gain
    K=P*H'*S^-1         # Kalman gain nxm

    # Posterior
    P=(I-K*H)*P         # Posterior covariance of x̂
    x̂ += K*y           # Posterior x estimate
end

x, x̂
