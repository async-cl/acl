package scuts.core;

enum Either < L, R > {
  Left(l:L);
  Right(r:R);
}


// newtype wrapper for left projections
@:coreType abstract LeftProjection<L,R> from Either<L,R> {}

// newtype wrapper for right projections
@:coreType abstract RightProjection<L,R> from Either<L,R> {}
