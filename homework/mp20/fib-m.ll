; ModuleID = 'fib.c'
source_filename = "fib.c"
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

@.str = private unnamed_addr constant [4 x i8] c"%d\0A\00", align 1

; Definition of fib function
; Function Attrs: nounwind uwtable
define i32 @fib(i32 %n) #0 {
entry:
  %n.addr = alloca i32, align 4
  store i32 %n, i32* %n.addr, align 4
  %0 = load i32, i32* %n.addr, align 4
  ; compare n with 0
  %tobool1 = icmp eq i32 %0, 0
  br i1 %tobool1, label %cond1.true, label %cond1.false

cond1.true:    ; n == 0
  br label %cond.end

cond1.false:
  ; compare n with 1
  %tobool2 = icmp eq i32 %0, 1
  br i1 %tobool2, label %cond2.true, label %cond2.false

cond2.true:    ; n == 1
  br label %cond.end

cond2.false:    ; n > 1
  %1 = sub nuw i32 %0, 2
  %call1 = call i32 @fib(i32 %1)    ; get fib(n-2)
  %2 = sub nuw i32 %0, 1
  %call2 = call i32 @fib(i32 %2)    ; get fib(n-1)
  %add = add nuw i32 %call1, %call2
  br label %cond.end

cond.end:
  ; union return values in three conditions
  %retval = phi i32 [ 0, %cond1.true ], [ 1, %cond2.true ], [ %add, %cond2.false ]
  ret i32 %retval
}

; Definition of main function
; Function Attrs: nounwind uwtable
define i32 @main(i32 %argc, i8** %argv) #0 {
  %argc.addr = alloca i32, align 4
  store i32 %argc, i32* %argc.addr, align 4
  %argv.addr = alloca i8**, align 4    ; type of argv is i8**
  store i8** %argv, i8*** %argv.addr, align 4
  %retval = alloca i32, align 4
  store i32 0, i32* %retval, align 4

  %idx = getelementptr i8*, i8** %argv, i64 1    ; idx points to the first string in argv[]
  %1 = load i8*, i8** %idx, align 4
  %call = call i32 @atoi(i8* %1)
  %fib = call i32 @fib(i32 %call)    ; call fib(n)
  %call2 = call i32 (i8*, ...) @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.str, i32 0, i32 0), i32 %fib)

  ret i32 0
}

declare i32 @printf(i8*, ...) #1
declare i32 @atoi(i8*) #2

attributes #0 = { nounwind uwtable "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }

attributes #1 = { "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }

attributes #2 = { "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "stack-protector-buffer-size"="8" "target-cpu"="x86-64" "target-features"="+fxsr,+mmx,+sse,+sse2,+x87" "unsafe-fp-math"="false" "use-soft-float"="false" }

