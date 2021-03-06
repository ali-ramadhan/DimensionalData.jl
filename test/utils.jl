using DimensionalData, Test, Dates
using DimensionalData: flip

@testset "reversing methods" begin
    revdima = reverse(ArrayOrder, X(10:10:20; mode=Sampled(order=Ordered(), span=Regular(10))))
    @test val(revdima) == 10:10:20
    @test order(revdima) == Ordered(ForwardIndex(), ReverseArray(), ReverseRelation())
    @test span(revdima) == Regular(10)
    revdimi = reverse(IndexOrder, X(10:10:20; mode=Sampled(order=Ordered(), span=Regular(10))))
    @test val(revdimi) == 20:-10:10
    @test order(revdimi) == Ordered(ReverseIndex(), ForwardArray(), ReverseRelation())
    @test span(revdimi) == Regular(-10)

    A = [1 2 3; 4 5 6]
    da = DimArray(A, (X(10:10:20), Y(300:-100:100)), :test)
    s = DimStack(da)

    reva = reverse(ArrayOrder, da; dims=Y)
    @test reva == [3 2 1; 6 5 4]
    @test val(dims(reva, X)) == 10:10:20
    @test val(dims(reva, Y)) == 300:-100:100
    @test order(dims(reva, X)) == Ordered(ForwardIndex(), ForwardArray(), ForwardRelation())
    @test order(dims(reva, Y)) == Ordered(ReverseIndex(), ReverseArray(), ReverseRelation())

    revi = reverse(IndexOrder, da; dims=Y)
    @test revi == A
    @test val(dims(revi, X)) == 10:10:20
    @test val(dims(revi, Y)) == 100:100:300
    @test order(dims(revi, X)) == Ordered(ForwardIndex(), ForwardArray(), ForwardRelation())

    revas = reverse(ArrayOrder, s; dims=Y)
    @test reva == [3 2 1; 6 5 4]
    @test val(dims(revas, X)) == 10:10:20
    @test val(dims(revas, Y)) == 300:-100:100
    @test order(dims(revas, X)) == Ordered(ForwardIndex(), ForwardArray(), ForwardRelation())
    @test order(dims(revas, Y)) == Ordered(ReverseIndex(), ReverseArray(), ReverseRelation())

    revis = reverse(IndexOrder, s; dims=Y)
    span(reverse(IndexOrder, mode(dims(revis, X))))
    span(dims(revis, X))
    @test revis[:test] == A
    @test val(dims(revis, X)) == 10:10:20
    @test val(dims(revis, Y)) == 100:100:300
    @test order(dims(revis, X)) == Ordered(ForwardIndex(), ForwardArray(), ForwardRelation())


    reoa = reorder(da, ReverseArray())
    @test reoa == [6 5 4; 3 2 1]
    @test val(dims(reoa, X)) == 10:10:20
    @test val(dims(reoa, Y)) == 300:-100:100
    @test order(dims(reoa, X)) == Ordered(ForwardIndex(), ReverseArray(), ReverseRelation())
    @test order(dims(reoa, Y)) == Ordered(ReverseIndex(), ReverseArray(), ReverseRelation())

    reoi = reorder(da, ReverseIndex, (X(), Y()))
    @test reoi == A 
    @test val(dims(reoi, X)) == 20:-10:10
    @test val(dims(reoi, Y)) == 300:-100:100
    @test order(dims(reoi, X)) == Ordered(ReverseIndex(), ForwardArray(), ReverseRelation())
    @test order(dims(reoi, Y)) == Ordered(ReverseIndex(), ForwardArray(), ForwardRelation())

    reoi = reorder(da, (Y=ForwardIndex, X=ReverseIndex))
    @test reoi == A
    @test val(dims(reoi, X)) == 20:-10:10
    @test val(dims(reoi, Y)) == 100:100:300
    @test order(dims(reoi, X)) == Ordered(ReverseIndex(), ForwardArray(), ReverseRelation())
    @test order(dims(reoi, Y)) == Ordered(ForwardIndex(), ForwardArray(), ReverseRelation())

    reor = reorder(da, X => ReverseRelation, Y => ForwardRelation)
    @test reor == [4 5 6; 1 2 3]
    @test val(dims(reor, X)) == 10:10:20
    @test val(dims(reor, Y)) == 300:-100:100
    @test order(dims(reor, X)) == Ordered(ForwardIndex(), ReverseArray(), ReverseRelation())
    @test order(dims(reor, Y)) == Ordered(ReverseIndex(), ForwardArray(), ForwardRelation())

    revallis = reverse(IndexOrder, da; dims=(X, Y))
    @test index(revallis) == (20:-10:10, 100:100:300)
    @test indexorder(revallis) == (ReverseIndex(), ForwardIndex())

    @testset "Val index" begin
        dav = DimArray(A, (X(Val((10, 20)); mode=Sampled(order=Ordered())), 
                           Y(Val((300, 200, 100)); mode=Sampled(order=Ordered(ReverseIndex(), ForwardArray(), ForwardRelation())))), :test)
        revdav = reverse(IndexOrder, dav; dims=(X, Y))
        @test val(revdav) == (Val((20, 10)), Val((100, 200, 300)))
    end
end

@testset "flip" begin
    A = [1 2 3; 4 5 6]
    da = DimArray(A, (X(10:10:20), Y(300:-100:100)), :test)
    fda = flip(IndexOrder, da; dims=(X, Y))
    @test indexorder(fda) == (ReverseIndex(), ForwardIndex())
    fda = flip(Relation, da, Y)
    @test relation(fda, Y) == ReverseRelation()
end

@testset "diff" begin
    @testset "Array 2D" begin
        y = Y(['a', 'b', 'c'])
        ti = Ti(DateTime(2021, 1):Month(1):DateTime(2021, 4))
        data = [-87  -49  107  -18
                24   44  -62  124
                122  -11   48   -7]
        A = DimArray(data, (y, ti))
        @test diff(A; dims=1) == diff(A; dims=Y) == diff(A; dims=:Y) == diff(A; dims=y) == DimArray([111 93 -169 142; 98 -55 110 -131], (Y(['b', 'c']), ti))
        @test diff(A; dims=2) == diff(A; dims=Ti) == diff(A; dims=:Ti) == diff(A; dims=ti) == DimArray([38 156 -125; 20 -106 186; -133 59 -55], (y, Ti(DateTime(2021, 2):Month(1):DateTime(2021, 4))))
        @test_throws MethodError diff(A; dims='X')
        @test_throws ArgumentError diff(A; dims=Z)
        @test_throws ArgumentError diff(A; dims=3)
    end
    @testset "Vector" begin
        x = DimArray([56, -123, -60, -44, -64, 70, 52, -48, -74, 86], X(2:2:20))
        @test diff(x) == diff(x; dims=1) == diff(x; dims=X) == DimArray([-179, 63, 16, -20, 134, -18, -100, -26, 160], X(4:2:20))
    end
end

@testset "modify" begin
    A = [1 2 3; 4 5 6]
    dimz = (X(10:10:20), Y(300:-100:100))
    @testset "array" begin
        da = DimArray(A, dimz)
        mda = modify(A -> A .> 3, da)
        @test dims(mda) === dims(da)
        @test mda == [false false false; true true true]
        @test typeof(parent(mda)) == BitArray{2}
        @test_throws ErrorException modify(A -> A[1, :], da)
    end
    @testset "dataset" begin
        da1 = DimArray(A, dimz, :da1)
        da2 = DimArray(2A, dimz, :da2)
        s = DimStack(da1, da2)
        ms = modify(A -> A .> 3, s)
        @test data(ms) == (da1=[false false false; true true true],
                              da2=[false true  true ; true true true])
        @test typeof(parent(ms[:da2])) == BitArray{2}
    end
    @testset "dimension" begin
        dim = X(10:10:20)
        mdim = modify(x -> 3 .* x, dim)
        @test index(mdim) === 30:30:60
        dim = Y(Val((1,2,3,4,5)))
        mdim = modify(xs -> 2 .* xs, dim)
        @test index(mdim) === (2, 4, 6, 8, 10)
        da = DimArray(A, dimz)
        mda = modify(y -> vec(4 .* y), da, Y)
        @test index(mda, Y) == [1200.0, 800.0, 400.0]
    end
end

@testset "dimwise" begin
    A2 = [1 2 3; 4 5 6]
    B1 = [1, 2, 3]
    da2 = DimArray(A2, (X([20, 30]), Y([:a, :b, :c])))
    db1 = DimArray(B1, (Y([:a, :b, :c]),))
    dc2 = dimwise(+, da2, db1)
    @test dc2 == [2 4 6; 5 7 9]

    A3 = cat([1 2 3; 4 5 6], [11 12 13; 14 15 16]; dims=3)
    da3 = DimArray(A3, (X, Y, Z))
    db2 = DimArray(A2, (X, Y))
    dc3 = dimwise(+, da3, db2)
    @test dc3 == cat([2 4 6; 8 10 12], [12 14 16; 18 20 22]; dims=3)

    A3 = cat([1 2 3; 4 5 6], [11 12 13; 14 15 16]; dims=3)
    da3 = DimArray(A3, (X([20, 30]), Y([:a, :b, :c]), Z(10:10:20)))
    db1 = DimArray(B1, (Y([:a, :b, :c]),))
    dc3 = dimwise(+, da3, db1)
    @test dc3 == cat([2 4 6; 5 7 9], [12 14 16; 15 17 19]; dims=3)

    @testset "works with permuted dims" begin
        db2p = permutedims(da2)
        dc3p = dimwise(+, da3, db2p)
        @test dc3p == cat([2 4 6; 8 10 12], [12 14 16; 18 20 22]; dims=3)
    end

end
