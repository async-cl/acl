package scuts.core;


enum Validation < F, S > {
  Failure(f:F);
  Success(s:S);
}

@:coreType abstract FailProjection<F,S> {}

