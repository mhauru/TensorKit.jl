# TODO Include all the others.
@testset "Sectors and fusion trees for sector $G" for G in (FibonacciAnyon,)# ℤ₂, ℤ₃, ℤ₄, U₁, CU₁, SU₂, ℤ₃ × ℤ₄, U₁ × SU₂, SU₂ × SU₂)
    @testset "Sector $G: Basic properties" begin
        s = (randsector(G), randsector(G), randsector(G))
        @test eval(Meta.parse(sprint(show,G))) == G
        @test eval(Meta.parse(sprint(show,s[1]))) == s[1]
        @test @inferred(one(s[1])) == @inferred(one(G))
        @inferred dual(s[1])
        @inferred dim(s[1])
        @inferred frobeniusschur(s[1])
        @inferred Nsymbol(s...)
        @inferred Rsymbol(s...)
        @inferred Bsymbol(s...)
        @inferred Fsymbol(s..., s...)
        it = @inferred s[1] ⊗ s[2]
        @inferred ⊗(s..., s...)
    end
    if hasmethod(fusiontensor, Tuple{G,G,G})
        @testset "Sector $G: fusion tensor and F-move and R-move" begin
            using TensorKit: fusiontensor
            for a in smallset(G), b in smallset(G)
                for c in ⊗(a,b)
                    @test permutedims(fusiontensor(a,b,c),(2,1,3)) ≈ Rsymbol(a,b,c)*fusiontensor(b,a,c)
                end
            end
            for a in smallset(G), b in smallset(G), c in smallset(G)
                for e in ⊗(a,b), f in ⊗(b,c)
                    for d in intersect(⊗(e,c), ⊗(a,f))
                        X1 = fusiontensor(a,b,e)
                        X2 = fusiontensor(e,c,d)
                        Y1 = fusiontensor(b,c,f)
                        Y2 = fusiontensor(a,f,d)
                        @tensor f1 = conj(Y2[a,f,d])*conj(Y1[b,c,f])*X1[a,b,e]*X2[e,c,d]
                        f2 = Fsymbol(a,b,c,d,e,f)*dim(d)
                        @test f1≈f2 atol=1e-12
                    end
                end
            end
        end
    end
    @testset "Sector $G: Unitarity of F-move" begin
        for a in smallset(G), b in smallset(G), c in smallset(G)
            for d in ⊗(a,b,c)
                es = collect(intersect(⊗(a,b), map(dual, ⊗(c,dual(d)))))
                fs = collect(intersect(⊗(b,c), map(dual, ⊗(dual(d),a))))
                @test length(es) == length(fs)
                F = [Fsymbol(a,b,c,d,e,f) for e in es, f in fs]
                @test F'*F ≈ one(F)
            end
        end
    end
    @testset "Sector $G: Pentagon equation" begin
        (a,b,c,d) = (randsector(G), randsector(G), randsector(G), randsector(G))
        for f in ⊗(a,b), j in ⊗(c,d)
            for g in ⊗(f,c), i in ⊗(b,j)
                for e in intersect(⊗(g,d), ⊗(a,i))
                    p1 = Fsymbol(f,c,d,e,g,j)*Fsymbol(a,b,j,e,f,i)
                    p2 = zero(p1)
                    for h in ⊗(b,c)
                        p2 += Fsymbol(a,b,c,g,f,h)*Fsymbol(a,h,d,e,g,i)*Fsymbol(b,c,d,i,h,j)
                    end
                    @test isapprox(p1, p2; atol=10*eps())
                end
            end
        end
    end
    @testset "Sector $G: Hexagon equation" begin
        (a,b,c) = (randsector(G), randsector(G), randsector(G))
        for e in ⊗(a,b), f in ⊗(b,c)
            for d in intersect(⊗(e,c), ⊗(a,f))
                p1 = Rsymbol(a,b,e)*Fsymbol(b,a,c,d,e,f)*Rsymbol(a,c,f)
                p2 = zero(p1)
                for h in ⊗(b,c)
                    p2 += Fsymbol(a,b,c,d,e,h)*Rsymbol(a,h,d)*Fsymbol(b,c,a,d,h,f)
                end
                @test isapprox(p1, p2; atol=10*eps())
            end
        end
    end

    @testset "Sector $G: Fusion trees" begin
        N = 5
        out = ntuple(n->randsector(G), StaticLength(N))
        in = rand(collect(⊗(out...)))
        numtrees = count(n->true, fusiontrees(out, in))
        while !(0 < numtrees < 30)
            out = ntuple(n->randsector(G), StaticLength(N))
            in = rand(collect(⊗(out...)))
            numtrees = count(n->true, fusiontrees(out, in))
        end

        it = @inferred fusiontrees(out, in)
        f, state = iterate(it)

        @inferred braid(f, 2)

        # test permutation
        p = tuple(randperm(N)...,)
        ip = invperm(p)

        d = @inferred TensorKit.permute(f, p)
        d2 = Dict{typeof(f), valtype(d)}()
        for (f2, coeff) in d
            for (f1,coeff2) in TensorKit.permute(f2, ip)
                d2[f1] = get(d2, f1, zero(coeff)) + coeff2*coeff
            end
        end
        for (f1, coeff2) in d2
            if f1 == f
                @test coeff2 ≈ 1
            else
                @test isapprox(coeff2, 0; atol = 10*eps())
            end
        end

        if hasmethod(fusiontensor, Tuple{G,G,G})
            Af = convert(Array, f)
            Afp = permutedims(Af, (p..., N+1))
            Afp2 = zero(Afp)
            for (f1, coeff) in d
                Afp2 .+= coeff .* convert(Array, f1)
            end
            @test Afp ≈ Afp2
        end

        # test insertat
        N = 4
        out2 = ntuple(n->randsector(G), StaticLength(N))
        in2 = rand(collect(⊗(out2...)))
        f2 = rand(collect(fusiontrees(out2, in2)))
        for i = 1:N
            out1 = ntuple(n->randsector(G), StaticLength(N))
            out1 = Base.setindex(out1, in2, i)
            in1 = rand(collect(⊗(out1...)))
            f1 = rand(collect(fusiontrees(out1, in1)))

            trees = @inferred insertat(f1, i, f2)
            @test norm(values(trees)) ≈ 1

            gen = Base.Generator(TensorKit.permute(f1, (i, (1:i-1)..., (i+1:N)...))) do (t, coeff)
                (t′, coeff′) = first(insertat(t, 1, f2))
                @test coeff′ == one(coeff′)
                return t′ => coeff
            end
            trees2 = Dict(gen)
            trees3 = empty(trees2)
            for (t,coeff) in trees2
                p = ((N .+ (1:i-1))..., (1:N)..., ((N-1) .+ (i+1:N))...)
                for (t′,coeff′) in TensorKit.permute(t, p)
                    trees3[t′] = get(trees3, t′, zero(coeff′)) + coeff*coeff′
                end
            end
            for (t, coeff) in trees3
                @test get(trees, t, zero(coeff)) ≈ coeff atol = 1e-12
            end

            if hasmethod(fusiontensor, Tuple{G,G,G})
                Af1 = convert(Array, f1)
                Af2 = convert(Array, f2)
                Af = TensorOperations.tensorcontract(Af1, [1:i-1; -1; N-1 .+ (i+1:N+1)],
                                                     Af2, [i-1 .+ (1:N); -1], 1:2N)
                Af′ = zero(Af)
                for (f, coeff) in trees
                    Af′ .+= coeff .* convert(Array, f)
                end
                @test Af ≈ Af′
            end
        end

        # test merge
        N = 3
        out1 = ntuple(n->randsector(G), StaticLength(N))
        in1 = rand(collect(⊗(out1...)))
        f1 = rand(collect(fusiontrees(out1, in1)))
        out2 = ntuple(n->randsector(G), StaticLength(N))
        in2 = rand(collect(⊗(out2...)))
        f2 = rand(collect(fusiontrees(out2, in2)))
        trees = @inferred merge(f1, f2)
        @test sum(abs2(c)*dim(f.coupled) for (f,c) in trees) ≈ dim(f1.coupled)*dim(f2.coupled)

        if hasmethod(fusiontensor, Tuple{G,G,G})
            Af1 = convert(Array, f1)
            Af2 = convert(Array, f2)
            for c in f1.coupled ⊗ f2.coupled
                Af0 = convert(Array, FusionTree((f1.coupled, f2.coupled), c, ()))
                _Af = TensorOperations.tensorcontract(Af1, [1:N;-1],
                                                        Af0, [-1;N+1;N+2], 1:N+2)
                Af = TensorOperations.tensorcontract(Af2, [N .+ (1:N); -1],
                                                        _Af, [1:N; -1; 2N+1], 1:2N+1)
                Af′ = zero(Af)
                for (f, coeff) in trees
                    if f.coupled == c
                        Af′ .+= coeff .* convert(Array, f)
                    end
                end
                @test Af ≈ Af′
            end
        end
    end
    @testset "Sector $G: Double fusion trees" begin
        if G <: ProductSector
            N = 3
        else
            N = 4
        end
        out = ntuple(n->randsector(G), StaticLength(N))
        numtrees = count(n->true, fusiontrees((out..., map(dual, out)...)))
        while !(0 < numtrees < 100)
            out = ntuple(n->randsector(G), StaticLength(N))
            numtrees = count(n->true, fusiontrees((out..., map(dual, out)...)))
        end
        in = rand(collect(⊗(out...)))
        f1 = rand(collect(fusiontrees(out, in)))
        f2 = rand(collect(fusiontrees(out[randperm(N)], in)))

        for n = 0:2*N
            d = @inferred repartition(f1, f2, StaticLength(n))
            d2 = Dict{typeof((f1,f2)), valtype(d)}()
            for ((f1′,f2′),coeff) in d
                for ((f1′′,f2′′),coeff2) in repartition(f1′,f2′, StaticLength(N))
                    d2[(f1′′,f2′′)] = get(d2, (f1′′,f2′′), zero(coeff)) + coeff2*coeff
                end
            end
            for ((f1′,f2′), coeff2) in d2
                if f1 == f1′ && f2 == f2′
                    @test coeff2 ≈ 1
                    if !(coeff2 ≈ 1)
                        @show f1, f2, n
                    end
                else
                    @test isapprox(coeff2, 0; atol = 10*eps())
                end
            end
        end

        p = (randperm(2*N)...,)
        p1, p2 = p[1:2], p[3:2N]
        ip = invperm(p)
        ip1, ip2 = ip[1:N], ip[N+1:2N]

        d = @inferred TensorKit.permute(f1, f2, p1, p2)
        d2 = Dict{typeof((f1,f2)), valtype(d)}()
        for ((f1′,f2′), coeff) in d
            d′ = TensorKit.permute(f1′,f2′, ip1, ip2)
            for ((f1′′,f2′′), coeff2) in d′
                d2[(f1′′,f2′′)] = get(d2, (f1′′,f2′′), zero(coeff)) + coeff2*coeff
            end
        end
        for ((f1′,f2′), coeff2) in d2
            if f1 == f1′ && f2 == f2′
                @test coeff2 ≈ 1
                if !(coeff2 ≈ 1)
                    @show f1, f2, p
                end
            else
                @test abs(coeff2) < 10*eps()
            end
        end
    end
end
