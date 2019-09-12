VFibonacciAnyon = (ℂ[FibonacciAnyon](:I=>1, :τ=>1),
                   ℂ[FibonacciAnyon](:I=>1, :τ=>2)',
                   ℂ[FibonacciAnyon](:I=>3, :τ=>2)',
                   ℂ[FibonacciAnyon](:I=>2, :τ=>3),
                   ℂ[FibonacciAnyon](:I=>2, :τ=>5)')
Vtr = (ℂ^2,
        (ℂ^3)',
        ℂ^4,
        ℂ^5,
        (ℂ^6)')
Vℤ₂ = (ℂ[ℤ₂](0=>1, 1=>1),
        ℂ[ℤ₂](0=>1, 1=>2)',
        ℂ[ℤ₂](0=>3, 1=>2)',
        ℂ[ℤ₂](0=>2, 1=>3),
        ℂ[ℤ₂](0=>2, 1=>5))
Vℤ₃ = (ℂ[ℤ₃](0=>1, 1=>1, 2=>2),
        ℂ[ℤ₃](0=>3, 1=>2, 2=>1),
        ℂ[ℤ₃](0=>2, 1=>3, 2=>1),
        ℂ[ℤ₃](0=>1, 1=>2, 2=>3)',
        ℂ[ℤ₃](0=>2, 1=>4, 2=>3)')
VU₁ = (ℂ[U₁](0=>1, 1=>1, -1=>2),
        ℂ[U₁](0=>3, 1=>2, -1=>1),
        ℂ[U₁](0=>2, 1=>3, -1=>1),
        ℂ[U₁](0=>1, 1=>2, -1=>3)',
        ℂ[U₁](0=>2, 1=>4, -1=>3)')
VCU₁ = (ℂ[CU₁]((0,0)=>1, (0,1)=>1, 1=>2),
        ℂ[CU₁]((0,0)=>3, (0,1)=>2, 1=>1),
        ℂ[CU₁]((0,0)=>2, (0,1)=>3, 1=>1),
        ℂ[CU₁]((0,0)=>1, (0,1)=>2, 1=>3)',
        ℂ[CU₁]((0,0)=>2, (0,1)=>4, 1=>3)')
VSU₂ = (ℂ[SU₂](0=>1, 1//2=>1),
        ℂ[SU₂](0=>2, 1//2=>1, 1=>1),
        ℂ[SU₂](1//2=>2, 1=>1),
        ℂ[SU₂](0=>1, 1//2=>3)',
        ℂ[SU₂](0=>2, 3//2=>1)')

# TODO Include all the others.
for (G,V) in ((FibonacciAnyon, VFibonacciAnyon), )#(Trivial, Vtr), (ℤ₂, Vℤ₂), (ℤ₃, Vℤ₃), (U₁, VU₁), (CU₁, VCU₁), (SU₂, VSU₂))
    println("------------------------------------")
    println("Tensors with symmetry: $G")
    println("------------------------------------")
    V1, V2, V3, V4, V5 = V
    @testset "Basic tensor properties" begin
        W = V1 ⊗ V2 ⊗ V3 ⊗ V4 ⊗ V5
        for T in (Int, Float32, Float64, ComplexF32, ComplexF64, BigFloat)
            t = Tensor(zeros, T, W)
            @test eltype(t) == T
            @test norm(t) == 0
            @test codomain(t) == W
            @test space(t) == W
            @test domain(t) == one(W)
        end
    end
    @testset "Basic linear algebra" begin
        W = V1 ⊗ V2 ⊗ V3 ← V4 ⊗ V5
        for T in (Float32, Float64, ComplexF32, ComplexF64)
            t = TensorMap(rand, T, W)
            @test eltype(t) == T
            @test codomain(t) == W.second
            @test domain(t) == W.first
            #@test isa(@inferred(norm(t)), real(T))  # TODO This fails e.g. if dim returns a Float64, and T == Float32.
            @test norm(t)^2 ≈ dot(t,t)
            α = rand(T)
            @test norm(α*t) ≈ abs(α)*norm(t)
            @test norm(t+t, 2) ≈ 2*norm(t, 2)
            @test norm(t+t, 1) ≈ 2*norm(t, 1)
            @test norm(t+t, Inf) ≈ 2*norm(t, Inf)
            p = 3*rand(Float64)
            @test norm(t+t, p) ≈ 2*norm(t, p)

            t2 = TensorMap(rand, T, W)
            β = rand(T)
            @test dot(β*t2,α*t) ≈ conj(β)*α*conj(dot(t,t2))
        end
    end
    @testset "Basic linear algebra: test via conversion" begin
        W = V1 ⊗ V2 ⊗ V3 ← V4 ⊗ V5
        for T in (Float32, Float64, ComplexF32, ComplexF64)
            t = TensorMap(rand, T, W)
            t2 = TensorMap(rand, T, W)
            @test norm(t, 2) ≈ norm(convert(Array,t), 2)
            @test dot(t2,t) ≈ dot(convert(Array,t2), convert(Array, t))
            α = rand(T)
            @test convert(Array, α*t) ≈ α*convert(Array,t)
            @test convert(Array, t+t) ≈ 2*convert(Array,t)
        end
    end
    @testset "Permutations: test via inner product invariance" begin
        W = V1 ⊗ V2 ⊗ V3 ⊗ V4 ⊗ V5
        t = Tensor(rand, ComplexF64, W);
        t′ = Tensor(rand, ComplexF64, W);
        for k = 0:5
            for p in permutations(1:5)
                p1 = ntuple(n->p[n], StaticLength(k))
                p2 = ntuple(n->p[k+n], StaticLength(5-k))
                t2 = @inferred permuteind(t, p1, p2)
                @test norm(t2) ≈ norm(t)
                t2′= permuteind(t′, p1, p2)
                @test dot(t2′,t2) ≈ dot(t′,t)
            end
        end
    end
    @testset "Permutations: test via conversion" begin
        W = V1 ⊗ V2 ⊗ V3 ⊗ V4 ⊗ V5
        t = Tensor(rand, ComplexF64, W);
        for k = 0:5
            for p in permutations(1:5)
                p1 = ntuple(n->p[n], StaticLength(k))
                p2 = ntuple(n->p[k+n], StaticLength(5-k))
                @test convert(Array, permuteind(t, p1, p2)) ≈ permutedims(convert(Array, t), (p1...,p2...))
            end
        end
    end
    @testset "Tensor contraction: test via conversion" begin
        A1 = TensorMap(randn, ComplexF64, V1'*V2', V3')
        A2 = TensorMap(randn, ComplexF64, V3*V4, V5)
        rhoL = TensorMap(randn, ComplexF64, V1, V1)
        rhoR = TensorMap(randn, ComplexF64, V5, V5)' # test adjoint tensor
        H = TensorMap(randn, ComplexF64, V2*V4, V2*V4)
        @tensor HrA12[a, s1, s2, c] := rhoL[a, a'] * conj(A1[a', t1, b]) *
            A2[b, t2, c'] * rhoR[c', c] * H[s1, s2, t1, t2]

        @tensor HrA12array[a, s1, s2, c] := convert(Array, rhoL)[a, a'] *
            conj(convert(Array, A1)[a', t1, b]) *
            convert(Array, A2)[b, t2, c'] *
            convert(Array, rhoR)[c', c] *
            convert(Array, H)[s1, s2, t1, t2]

        @test HrA12array ≈ convert(Array, HrA12)
    end
    @testset "Multiplication and inverse: test compatibility" begin
        W1 = V1 ⊗ V2 ⊗ V3
        W2 = V4 ⊗ V5
        for T in (Float64, ComplexF64)
            t1 = TensorMap(rand, T, W1, W1)
            t2 = TensorMap(rand, T, W2, W2)
            t = TensorMap(rand, T, W1, W2)
            @test t1*(t1\t) ≈ t
            @test (t/t2)*t2 ≈ t
            @test t1\one(t1) ≈ inv(t1)
            @test one(t1)/t1 ≈ pinv(t1)
            @test_throws SpaceMismatch inv(t)
            @test_throws SpaceMismatch t2\t
            @test_throws SpaceMismatch t/t1
            tp = pinv(t)*t
            @test tp ≈ tp*tp
        end
    end
    @testset "Multiplication and inverse: test via conversion" begin
        W1 = V1 ⊗ V2 ⊗ V3
        W2 = V4 ⊗ V5
        for T in (Float32, Float64, ComplexF32, ComplexF64)
            t1 = TensorMap(rand, T, W1, W1)
            t2 = TensorMap(rand, T, W2, W2)
            t = TensorMap(rand, T, W1, W2)
            d1 = dim(W1)
            d2 = dim(W2)
            At1 = reshape(convert(Array, t1), d1, d1)
            At2 = reshape(convert(Array, t2), d2, d2)
            At = reshape(convert(Array, t), d1, d2)
            @test reshape(convert(Array, t1*t), d1, d2) ≈ At1*At
            @test reshape(convert(Array, t1'*t), d1, d2) ≈ At1'*At
            @test reshape(convert(Array, t2*t'), d2, d1) ≈ At2*At'
            @test reshape(convert(Array, t2'*t'), d2, d1) ≈ At2'*At'

            @test reshape(convert(Array, inv(t1)), d1, d1) ≈ inv(At1)
            @test reshape(convert(Array, pinv(t)), d2, d1) ≈ pinv(At)

            if T == Float32 || T == ComplexF32
                continue
            end

            @test reshape(convert(Array, t1\t), d1, d2) ≈ At1\At
            @test reshape(convert(Array, t1'\t), d1, d2) ≈ At1'\At
            @test reshape(convert(Array, t2\t'), d2, d1) ≈ At2\At'
            @test reshape(convert(Array, t2'\t'), d2, d1) ≈ At2'\At'

            @test reshape(convert(Array, t2/t), d2, d1) ≈ At2/At
            @test reshape(convert(Array, t2'/t), d2, d1) ≈ At2'/At
            @test reshape(convert(Array, t1/t'), d1, d2) ≈ At1/At'
            @test reshape(convert(Array, t1'/t'), d1, d2) ≈ At1'/At'
        end
    end
    @testset "Factorization" begin
        W = V1 ⊗ V2 ⊗ V3 ⊗ V4 ⊗ V5
        for T in (Float32, Float64, ComplexF32, ComplexF64)
            t = Tensor(rand, T, W)
            @testset "leftorth with $alg" for alg in (TensorKit.QR(), TensorKit.QRpos(), TensorKit.QL(), TensorKit.QLpos(), TensorKit.Polar(), TensorKit.SVD(), TensorKit.SDD())
                Q, R = @inferred leftorth(t, (3,4,2),(1,5); alg = alg)
                QdQ = Q'*Q
                @test QdQ ≈ one(QdQ)
                @test Q*R ≈ permuteind(t, (3,4,2),(1,5))
            end
            @testset "leftnull with $alg" for alg in (TensorKit.QR(), TensorKit.QRpos())
                N = @inferred leftnull(t, (3,4,2),(1,5); alg = alg)
                NdN = N'*N
                @test NdN ≈ one(NdN)
                @test norm(N'*permuteind(t, (3,4,2),(1,5))) < 100*eps(norm(t))
            end
            @testset "rightorth with $alg" for alg in (TensorKit.RQ(), TensorKit.RQpos(), TensorKit.LQ(), TensorKit.LQpos(), TensorKit.Polar(), TensorKit.SVD(), TensorKit.SDD())
                L, Q = @inferred rightorth(t, (3,4),(2,1,5); alg = alg)
                QQd = Q*Q'
                @test QQd ≈ one(QQd)
                @test L*Q ≈ permuteind(t, (3,4),(2,1,5))
            end
            @testset "rightnull with $alg" for alg in (TensorKit.LQ(), TensorKit.LQpos())
                M = @inferred rightnull(t, (3,4),(2,1,5); alg = alg)
                MMd = M*M'
                @test MMd ≈ one(MMd)
                @test norm(permuteind(t, (3,4),(2,1,5))*M') < 100*eps(norm(t))
            end
            @testset "svd with $alg" for alg in (TensorKit.SVD(), TensorKit.SDD())
                U, S, V = @inferred svd(t, (3,4,2),(1,5); alg = alg)
                UdU = U'*U
                @test UdU ≈ one(UdU)
                VVd = V*V'
                @test VVd ≈ one(VVd)
                @test U*S*V ≈ permuteind(t, (3,4,2),(1,5))
            end

            t = Tensor(rand, T, V1 ⊗ V1' ⊗ V2 ⊗ V2')
            @testset "eig and isposdef" begin
                D, V = eigen(t, (1,3), (2,4))
                VdV = V'*V
                VdV = (VdV + VdV')/2
                @test isposdef(VdV)
                t2 = permuteind(t, (1,3), (2,4))
                @test t2*V ≈ V*D
                @test !isposdef(t2) # unlikely for non-hermitian map
                t2 = (t2 + t2');
                D, V = eigen(t2)
                VdV = V'*V
                @test VdV ≈ one(VdV)
                λ = minimum(minimum(real(diag(b))) for (c,b) in blocks(D))
                @test isposdef(t2) == isposdef(λ)
                @test isposdef(t2 - λ*one(t2) + 0.1*one(t2))
                @test !isposdef(t2 - λ*one(t2) - 0.1*one(t2))
            end
        end
    end
    @testset "Exponentiation" begin
        W = V1 ⊗ V2 ⊗ V3
        for T in (Float32, Float64, ComplexF32, ComplexF64)
            t = TensorMap(rand, T, W, W)
            s = dim(W)
            expt = @inferred exp(t)
            @test reshape(convert(Array, expt), (s,s)) ≈
                    exp(reshape(convert(Array, t), (s,s)))
        end
    end
    @testset "Tensor product: test via norm preservation" begin
        for T in (Float32, Float64, ComplexF32, ComplexF64)
            t1 = TensorMap(rand, T, V2 ⊗ V3 ⊗ V1, V1 ⊗ V2)
            t2 = TensorMap(rand, T, V2 ⊗ V1 ⊗ V3, V1 ⊗ V1)
            t = @inferred (t1 ⊗ t2)
            @test norm(t) ≈ norm(t1) * norm(t2)
        end
    end
    @testset "Tensor product: test via conversion" begin
        for T in (Float32, Float64, ComplexF32, ComplexF64)
            t1 = TensorMap(rand, T, V2 ⊗ V3 ⊗ V1, V1)
            t2 = TensorMap(rand, T, V2 ⊗ V1 ⊗ V3, V2)
            t = @inferred (t1 ⊗ t2)
            d1 = dim(codomain(t1))
            d2 = dim(codomain(t2))
            d3 = dim(domain(t1))
            d4 = dim(domain(t2))
            At = convert(Array, t)
            @show sizeof(At)
            @test reshape(At, (d1, d2, d3, d4)) ≈
                    reshape(convert(Array, t1), (d1, 1, d3, 1)) .*
                    reshape(convert(Array, t2), (1, d2, 1, d4))
        end
    end
    @testset "Tensor product: test via tensor contraction" begin
        for T in (Float32, Float64, ComplexF32, ComplexF64)
            t1 = Tensor(rand, T, V2 ⊗ V3 ⊗ V1)
            t2 = Tensor(rand, T, V2 ⊗ V1 ⊗ V3)
            t = @inferred (t1 ⊗ t2)
            @tensor t′[1, 2, 3, 4, 5, 6] := t1[1,2,3]*t2[4,5,6]
            @test t ≈ t′
        end
    end
end
