{
  Pascal port of the C++ global illumination renderer "smallpt" at http://www.kevinbeason.com/smallpt/
  Now with added real-time Mode 13 display! Compile with Turbo Pascal 4 using TURBO.EXE

  Dirk de la Hunt - noshbar@gmail.com
}

PROGRAM smallpt;

USES
  DOS;

TYPE
  FloatType = REAL;
  TFileName = STRING[32];

CONST
  M_PI : FloatType = 3.14159265358979323846;

TYPE
  TVector = RECORD
    x : FloatType;
    y : FloatType;
    z : FloatType;
  END;

TYPE
  TRay = RECORD
    Origin      : TVector;
    Direction   : TVector;
  END;

TYPE
  TSphere = RECORD
    Radius      : FloatType;
    Position    : TVector;
    Emission    : TVector;
    Colour      : TVector;
    SurfaceType : INTEGER;
  END;

CONST
  SurfaceType_Diffuse    = 0;
  SurfaceType_Specular   = 1;
  SurfaceType_Refractive = 2;

CONST
  Tile_Width             = 32;
  Tile_Height            = 32;

TYPE
  TVectorLine            = ARRAY[0..Tile_Width] OF TVector;
  TVectorLinePtr         = ^TVectorLine;

VAR
  spheres      : ARRAY[0..9] OF TSphere;
  Sphere_Count : INTEGER;

PROCEDURE Ray_Init(VAR Result : TRay; Origin, Direction : TVector);
BEGIN
  Result.Origin    := Origin;
  Result.Direction := Direction;
END;

FUNCTION Utils_erand48 : FloatType;
VAR
  test : FloatType;
BEGIN
  test := random(1024) / 1023;
  IF (test > 1) THEN
    test := 1;
  Utils_erand48 := test;
END;

FUNCTION Utils_fabs(value : FloatType) : FloatType;
BEGIN
  IF (value < 0) THEN
    Utils_fabs := value * -1
  ELSE
    Utils_fabs := value;
END;

FUNCTION Utils_clamp(value : FloatType) : FloatType;
BEGIN
  IF value < 0.0 THEN
    Utils_clamp := 0.0
  ELSE
  IF value > 1.0 THEN
    Utils_clamp := 1.0
  ELSE
    Utils_clamp := value;
END;

FUNCTION Utils_power(Number, Exponent : FloatType) : FloatType;
BEGIN
  IF (Number = 0) OR (Exponent = 0) THEN
    Utils_power := 0
  ELSE
    Utils_power := Exp(Exponent * Ln(Number));
END;

FUNCTION Utils_toInt(value : FloatType) : INTEGER;
BEGIN
  Utils_toInt := round(Utils_power(Utils_clamp(value), 1.0 / 2.2) * 255.0 + 0.5);
END;

PROCEDURE Vector_Init(VAR Result : TVector; x, y, z : FloatType);
BEGIN
  Result.x := x;
  Result.y := y;
  Result.z := z;
END;

PROCEDURE Vector_Add(VAR Result : TVector; a, b : TVector);
BEGIN
  Result.x := a.x + b.x;
  Result.y := a.y + b.y;
  Result.z := a.z + b.z;
END;

PROCEDURE Vector_Add3(VAR Result : TVector; a, b, c : TVector);
BEGIN
  Result.x := a.x + b.x + c.x;
  Result.y := a.y + b.y + c.y;
  Result.z := a.z + b.z + c.z;
END;

PROCEDURE Vector_Sub(VAR Result : TVector; a, b : TVector);
BEGIN
  Result.x := a.x - b.x;
  Result.y := a.y - b.y;
  Result.z := a.z - b.z;
END;

PROCEDURE Vector_MultiplyVec(VAR Result : TVector; a, b : TVector);
BEGIN
  Result.x := a.x * b.x;
  Result.y := a.y * b.y;
  Result.z := a.z * b.z;
END;

PROCEDURE Vector_MultiplyFloat(VAR Result : TVector; a : TVector; value : FloatType);
BEGIN
  Result.x := a.x * value;
  Result.y := a.y * value;
  Result.z := a.z * value;
END;

PROCEDURE Vector_Normalise(VAR Result : TVector; a : TVector);
VAR
  m : FloatType;
BEGIN
  m := sqrt(a.x * a.x + a.y * a.y + a.z * a.z);
  IF (m = 0) THEN
  BEGIN
    Result.x := 0;
    Result.y := 0;
    Result.z := 0;
  END ELSE
  BEGIN
    Result.x := a.x / m;
    Result.y := a.y / m;
    Result.z := a.z / m;
  END;
END;

FUNCTION Vector_Dot(a, b : TVector) : FloatType;
BEGIN
  Vector_Dot := a.x * b.x + a.y * b.y + a.z * b.z;
END;

PROCEDURE Vector_Cross(VAR Result : TVector; a, b : TVector);
BEGIN
  Result.x := a.y * b.z - a.z * b.y;
  Result.y := a.z * b.x - a.x * b.z;
  Result.z := a.x * b.y - a.y * b.x;
END;

PROCEDURE Sphere_Init(VAR Result : TSphere; Radius : FloatType; Position, Emission, Colour : TVector; SurfaceType : INTEGER);
BEGIN
  Result.Radius      := Radius;
  Result.Position    := Position;
  Result.Emission    := Emission;
  Result.Colour      := Colour;
  Result.SurfaceType := SurfaceType;
END;

FUNCTION Sphere_Intersect(VAR Sphere : TSphere; VAR Ray : TRay) : FloatType;
VAR
  op  : TVector;
  eps : FloatType;
  b   : FloatType;
  det : FloatType;
BEGIN
  Sphere_Intersect := 0;

  Vector_Sub(op, Sphere.Position, Ray.Origin);
  eps := 1e-4;
  b   := Vector_Dot(op, Ray.Direction);
  det := (b * b) - Vector_Dot(op, op) + (Sphere.Radius * Sphere.Radius);
  IF (det < 0.0) THEN
    EXIT
  ELSE
    det := sqrt(det);

  IF (b - det > eps) THEN
    Sphere_Intersect := b - det
  ELSE
  IF (b + det > eps) THEN
    Sphere_Intersect := b + det;
END;

FUNCTION Engine_Intersect(VAR Ray : TRay; VAR Distance : FloatType; VAR Id : INTEGER) : BOOLEAN;
VAR
  infinity : FloatType;
  index    : INTEGER;
  d        : FloatType;
BEGIN
  infinity := 1e20;
  Distance := infinity;

  FOR index := Sphere_Count - 1 DOWNTO 0 DO
  BEGIN
    d := Sphere_Intersect(spheres[index], Ray);
    IF (d <> 0) AND (d < Distance) THEN
    BEGIN
      Distance := d;
      Id       := index;
    END;
  END;
  Engine_Intersect := Distance < infinity;
END;

PROCEDURE Engine_Radiance(VAR Result : TVector; Ray : TRay; Depth : INTEGER);
VAR
  distance : FloatType;
  id       : INTEGER;
  sphere   : TSphere;
  x        : TVector;
  n        : TVector;
  nl       : TVector;
  f        : TVector;
  p        : FloatType;

  r1       : FloatType;
  r2       : FloatType;
  r2s      : FloatType;

  w        : TVector;
  u        : TVector;
  v        : TVector;
  d        : TVector;

  newRay   : TRay;
  into     : BOOLEAN;

  nc       : FloatType;
  nt       : FloatType;
  nnt      : FloatType;
  ddn      : FloatType;
  cos2t    : FloatType;

  a        : FloatType;
  b        : FloatType;
  c        : FloatType;
  R0       : FloatType;
  Re       : FloatType;
  Tr       : FloatType;
  RP       : FloatType;
  TP       : FloatType;
  tdir     : TVector;
  mult     : FloatType;
  foo      : TVector;

  cl       : TVector;
  clTemp   : TVector;
  cf       : TVector;
  r        : TRay;
  skipRest : BOOLEAN;

BEGIN
  Id       := 0;
  distance := 0;
  Vector_Init(cl, 0, 0, 0);
  Vector_Init(cf, 1, 1, 1);
  r := Ray;

  Vector_Init(Result, 0, 0, 0);

  WHILE (TRUE) DO
  BEGIN
    skipRest := FALSE;
    IF (NOT Engine_Intersect(r, distance, Id)) THEN
    BEGIN
      Result := cl;
      EXIT;
    END;

    sphere := spheres[id];        { the hit object }
    Vector_MultiplyFloat(x, r.Direction, distance);
    Vector_Add(x, x, r.Origin);
    Vector_Sub(n, x, sphere.Position);
    Vector_Normalise(n, n);
    nl := n;
    IF (Vector_Dot(n, r.Direction) >= 0) THEN
      Vector_MultiplyFloat(nl, nl, -1);
    f := sphere.Colour;

    IF (f.x > f.y) AND (f.x > f.z) THEN
      p := f.x
    ELSE
    IF (f.y > f.z) THEN
      p := f.y
    ELSE
      p := f.z;

    Vector_MultiplyVec(clTemp, cf, sphere.Emission);
    Vector_Add(cl, cl, clTemp);

    Depth := Depth + 1;
    IF (Depth > 5) OR (p = 0) THEN
      IF (Utils_erand48 < p) THEN
      BEGIN
        Vector_MultiplyFloat(f, f, 1 / p);
        IF (p = 1) AND (f.x = 1) AND (f.y = 1) AND (f.z = 1) THEN
        BEGIN
          Result := cl;
          EXIT;
        END;
      END ELSE
      BEGIN
        Result := cl;
        EXIT;
      END;

    Vector_MultiplyVec(cf, cf, f);

    IF (sphere.SurfaceType = SurfaceType_Diffuse) THEN
    BEGIN
      r1  := 2 * M_PI * Utils_erand48;
      r2  := Utils_erand48;
      r2s := sqrt(r2);
      w   := nl;

      IF (Utils_fabs(w.x) > 0.1) THEN
        Vector_Init(u, 0, 1, 0)
      ELSE
        Vector_Init(u, 1, 0, 0);
      Vector_Cross(u, u, w);
      Vector_Normalise(u, u);

      Vector_Cross(v, w, u);
      Vector_MultiplyFloat(u, u, cos(r1) * r2s);
      Vector_MultiplyFloat(v, v, sin(r1) * r2s);
      Vector_MultiplyFloat(w, w, sqrt(1 - r2));
      Vector_Add3(d, u, v, w);
      Vector_Normalise(d, d);
      Ray_Init(r, x, d);
      skipRest := TRUE;
    END ELSE
    IF (sphere.SurfaceType = SurfaceType_Specular) THEN
    BEGIN
      newRay.Origin := x;
      Vector_MultiplyFloat(newRay.Direction, n, 2);
      Vector_MultiplyFloat(newRay.Direction, newRay.Direction, Vector_Dot(n, r.Direction));
      Vector_Sub(newRay.Direction, r.Direction, newRay.Direction);
      r := newRay;
      skipRest := TRUE;
    END;

    IF (NOT skipRest) THEN
    BEGIN
      newRay.Origin := x;
      Vector_MultiplyFloat(newRay.Direction, n, 2);
      Vector_MultiplyFloat(newRay.Direction, newRay.Direction, Vector_Dot(n, r.Direction));
      Vector_Sub(newRay.Direction, r.Direction, newRay.Direction);
      into := Vector_Dot(n, nl) > 0;
      nc   := 1;
      nt   := 1.5;
      IF (into) THEN
      BEGIN
        nnt := nc / nt;
        mult := 1.0;
      END ELSE
      BEGIN
        nnt := nt / nc;
        mult := -1.0;
      END;
      ddn   := Vector_Dot(r.Direction, nl);
      cos2t := 1 - nnt * nnt * (1 - ddn * ddn);
      IF (cos2t < 0) THEN
      BEGIN
        r := newRay;
        skipRest := TRUE;
      END;

      IF (NOT skipRest) THEN
      BEGIN
        Vector_MultiplyFloat(foo, n, mult * (ddn * nnt + sqrt(cos2t)));
        Vector_MultiplyFloat(tdir, r.Direction, nnt);
        Vector_Sub(tdir, tdir, foo);
        Vector_Normalise(tdir, tdir);
        a  := nt - nc;
        b  := nt + nc;
        R0 := a * a / (b * b);
        IF (into) THEN
          c := 1 + ddn
        ELSE
          c := 1 - Vector_Dot(tdir, n);

        Re := R0 + (1 - R0) * c * c * c * c * c;
        Tr := 1 - Re;
        P  := 0.25 + 0.5 * Re;
        RP := Re / P;
        TP := Tr / (1 - P);

        IF (Utils_erand48 < p) THEN
        BEGIN
          Vector_MultiplyFloat(cf, cf, RP);
          r := newRay;
        END ELSE
        BEGIN
          Vector_MultiplyFloat(cf, cf, TP);
          Ray_Init(r, x, tdir);
        END;
      END;
    END;
  END;
END;

PROCEDURE Engine_Init;
BEGIN
  Sphere_Count := 0;

  spheres[Sphere_Count].Radius := 1e5;
  Vector_Init(spheres[Sphere_Count].Position, 1e5 + 1.0, 40.8, 81.6);
  Vector_Init(spheres[Sphere_Count].Emission, 0, 0, 0);
  Vector_Init(spheres[Sphere_Count].Colour, 0.75, 0.25, 0.25);
  spheres[Sphere_Count].SurfaceType := SurfaceType_Diffuse;
  Sphere_Count := Sphere_Count + 1;

  spheres[Sphere_Count].Radius := 1e5;
  Vector_Init(spheres[Sphere_Count].Position, -1e5 + 99, 40.8, 81.6);
  Vector_Init(spheres[Sphere_Count].Emission, 0, 0, 0);
  Vector_Init(spheres[Sphere_Count].Colour, 0.25, 0.25, 0.75);
  spheres[Sphere_Count].SurfaceType := SurfaceType_Diffuse;
  Sphere_Count := Sphere_Count + 1;

  spheres[Sphere_Count].Radius := 1e5;
  Vector_Init(spheres[Sphere_Count].Position, 50, 40.8, 1e5);
  Vector_Init(spheres[Sphere_Count].Emission, 0, 0, 0);
  Vector_Init(spheres[Sphere_Count].Colour, 0.75, 0.75, 0.75);
  spheres[Sphere_Count].SurfaceType := SurfaceType_Diffuse;
  Sphere_Count := Sphere_Count + 1;

  spheres[Sphere_Count].Radius := 1e5;
  Vector_Init(spheres[Sphere_Count].Position, 50, 40.8, -1e5 + 170);
  Vector_Init(spheres[Sphere_Count].Emission, 0, 0, 0);
  Vector_Init(spheres[Sphere_Count].Colour, 0, 0, 0);
  spheres[Sphere_Count].SurfaceType := SurfaceType_Diffuse;
  Sphere_Count := Sphere_Count + 1;

  spheres[Sphere_Count].Radius := 1e5;
  Vector_Init(spheres[Sphere_Count].Position, 50, 1e5, 81.6);
  Vector_Init(spheres[Sphere_Count].Emission, 0, 0, 0);
  Vector_Init(spheres[Sphere_Count].Colour, 0.75, 0.75, 0.75);
  spheres[Sphere_Count].SurfaceType := SurfaceType_Diffuse;
  Sphere_Count := Sphere_Count + 1;

  spheres[Sphere_Count].Radius := 1e5;
  Vector_Init(spheres[Sphere_Count].Position, 50, -1e5 + 81.6, 81.6);
  Vector_Init(spheres[Sphere_Count].Emission, 0, 0, 0);
  Vector_Init(spheres[Sphere_Count].Colour, 0.75, 0.75, 0.75);
  spheres[Sphere_Count].SurfaceType := SurfaceType_Diffuse;
  Sphere_Count := Sphere_Count + 1;

  spheres[Sphere_Count].Radius := 16.5;
  Vector_Init(spheres[Sphere_Count].Position, 27, 16.5, 47);
  Vector_Init(spheres[Sphere_Count].Emission, 0, 0, 0);
  Vector_Init(spheres[Sphere_Count].Colour, 1, 1, 1);
  spheres[Sphere_Count].SurfaceType := SurfaceType_Specular;
  Sphere_Count := Sphere_Count + 1;

  spheres[Sphere_Count].Radius := 16.5;
  Vector_Init(spheres[Sphere_Count].Position, 73, 16.5, 78);
  Vector_Init(spheres[Sphere_Count].Emission, 0, 0, 0);
  Vector_Init(spheres[Sphere_Count].Colour, 0.999, 0.999, 0.999);
  spheres[Sphere_Count].SurfaceType := SurfaceType_Refractive;
  Sphere_Count := Sphere_Count + 1;

  spheres[Sphere_Count].Radius := 600;
  Vector_Init(spheres[Sphere_Count].Position, 50, 681.6 - 0.27, 81.6);
  Vector_Init(spheres[Sphere_Count].Emission, 12, 12, 12);
  Vector_Init(spheres[Sphere_Count].Colour, 0, 0, 0);
  spheres[Sphere_Count].SurfaceType := SurfaceType_Diffuse;
  Sphere_Count := Sphere_Count + 1;
END;

FUNCTION getColourIndex(r, g, b : INTEGER) : BYTE;
VAR
  index : INTEGER;
BEGIN
  IF (r > 255) THEN r := 255;
  IF (g > 255) THEN g := 255;
  IF (b > 255) THEN b := 255;
  index := b DIV 51 * $24 + (g DIV 51 * $06) + (r DIV 51);
  IF (index > 255) THEN index := 255;
  getColourIndex := index;
END;

PROCEDURE Engine_Run(FileName : TFileName; Width : INTEGER; Height : INTEGER; Samples : INTEGER);
VAR
  y            : INTEGER;
  x            : INTEGER;
  sx           : INTEGER;
  sy           : INTEGER;
  i            : INTEGER;
  s            : INTEGER;
  lines        : ARRAY[0..Tile_Height] OF TVectorLinePtr;
  w            : INTEGER;
  h            : INTEGER;
  samps        : INTEGER;
  temp         : TVector;
  r1           : FloatType;
  r2           : FloatType;
  d            : TVector;
  dx           : FloatType;
  dy           : FloatType;
  cam          : TRay;
  tempRay      : TRay;
  cx           : TVector;
  cy           : TVector;
  camPosition  : TVector;
  camDirection : TVector;
  r            : TVector;
  tf           : Text;

  tileCountX   : INTEGER;
  tileCountY   : INTEGER;
  startX       : INTEGER;
  stopX        : INTEGER;
  startY       : INTEGER;
  stopY        : INTEGER;
  tileX        : INTEGER;
  tileY        : INTEGER;
BEGIN

  w := Width;
  IF (w > 320) THEN
    w := 320;
  IF (Odd(w)) THEN
    w := w - 1;

  h := Height;
  IF (h > 200) THEN
    h := 200;
  IF (Odd(h)) THEN
    h := h - 1;

  samps := Samples;

  Engine_Init;

  FOR y := 0 TO Tile_Height - 1 DO
  BEGIN
    New(lines[y]);
    FOR x := 0 TO Tile_Width - 1 DO
      Vector_Init(lines[y]^[x], 0, 0, 0);
  END;

  Vector_Init(camPosition, 50, 52, 295.6);
  Vector_Init(camDirection, 0, -0.042612, -1);
  Vector_Normalise(camDirection, camDirection);
  Ray_Init(cam, camPosition, camDirection);
  Vector_Init(cx, w * 0.5135 / h, 0, 0);
  Vector_Cross(cy, cx, cam.Direction);
  Vector_Normalise(cy, cy);
  Vector_MultiplyFloat(cy, cy, 0.5135);

  tileCountX := (w DIV Tile_Width) + 1;
  tileCountY := (h DIV Tile_Height) + 1;

  IF (Tile_Height = 1) THEN
  BEGIN
    Assign(tf, FileName);
    Rewrite(tf);
    writeln(tf, 'P3');
    writeln(tf, w, ' ', h);
    writeln(tf, 255);
  END;

  FOR tileY := 0 TO tileCountY - 1 DO
  BEGIN
    FOR tileX := 0 TO tileCountX - 1 DO
    BEGIN
      startY := tileY * Tile_Height;
      stopY  := (startY + Tile_Height);
      IF (stopY > h) THEN
        stopY := h;

      FOR y := 0 TO Tile_Height - 1 DO
        FOR x := 0 TO Tile_Width - 1 DO
          Vector_Init(lines[y]^[x], 0, 0, 0);

      FOR y := startY TO stopY - 1 DO
      BEGIN
        startX := tileX * Tile_Width;
        stopX  := (startX + Tile_Width);
        IF (stopX > w) THEN
          stopX := w;
        FOR x := startX TO stopX - 1 DO
        BEGIN
          i := y;
          FOR sy := 0 TO 1 DO
          BEGIN
            Vector_Init(r, 0, 0, 0);
            FOR sx := 0 TO 1 DO
            BEGIN
              FOR s := 0 TO samps - 1 DO
              BEGIN
                r1 := 2 * Utils_erand48;
                IF (r1 < 1) THEN
                  dx := sqrt(r1) - 1
                ELSE
                  dx := 1 - sqrt(2 - r1);

                r2 := 2 * Utils_erand48;
                IF (r2 < 1) THEN
                  dy := sqrt(r2) - 1
                ELSE
                  dy := 1 - sqrt(2 - r2);

                Vector_MultiplyFloat(temp, cx, ((sx + 0.5 + dx) / 2 + x) / w - 0.5);
                Vector_MultiplyFloat(d, cy, ((sy + 0.5 + dy) / 2 + (h - y - 1)) / h - 0.5);
                Vector_Add(d, d, temp);
                Vector_Add(d, d, cam.Direction);

                Vector_Normalise(d, d);
                Vector_MultiplyFloat(tempRay.Origin, d, 140);
                Vector_Add(tempRay.Origin, tempRay.Origin, cam.Origin);
                tempRay.Direction := d;
                Engine_Radiance(temp, tempRay, 0);
                Vector_MultiplyFloat(temp, temp, (1.0 / samps));
                Vector_Add(r, r, temp);
              END;
              temp.x := Utils_clamp(r.x);
              temp.y := Utils_clamp(r.y);
              temp.z := Utils_clamp(r.z);
              Vector_MultiplyFloat(temp, temp, 0.24);
              Vector_Add(lines[i - startY]^[x - startX], lines[i - startY]^[x - startX], temp);
              Vector_Init(r, 0, 0, 0);
            END;
          END;

          { Put the pixel on the screen }
          mem[$A000:x + (320 * i)] := getColourIndex(Utils_toInt(lines[i - startY]^[x-startX].x),
                                        Utils_toInt(lines[i-startY]^[x-startX].y),
                                        Utils_toInt(lines[i-startY]^[x-startX].z));
		  
          IF (Tile_Height = 1) THEN
            write(tf,
              Utils_toInt(lines[i - startY]^[x - startX].x), ' ',
              Utils_toInt(lines[i - startY]^[x - startX].y), ' ',
              Utils_toInt(lines[i - startY]^[x - startX].z), ' ');
        END;
      END;
    END;
  END;

  IF (Tile_Height = 1) THEN
    Close(tf);

  FOR y := 0 TO Tile_Height - 1 DO
    Dispose(lines[y]);
END;

PROCEDURE makePalette;
var
  index : integer;
  r,g,b : integer;
BEGIN
  index := 0;
  r     := 0;
  while (R < 256) DO
  BEGIN
    g := 0;
    while (g < 256) DO
    BEGIN
      b := 0;
      while (b < 256) DO
      BEGIN
        Port[$3c8] := index;
        Port[$3c9] := r SHR 2;
        Port[$3c9] := g SHR 2;
        Port[$3c9] := b SHR 2;
        index      := index + 1;
        b := b + 51;
      END;
      g := g + 51;
    END;
    r := r + 51;
  END;
END;

VAR
  Width    : INTEGER;
  Height   : INTEGER;
  Samples  : INTEGER;
  Response : CHAR;
  Regs     : REGISTERS;

BEGIN
  Response := 'Y';
  writeln('(When rendering is finished, press ENTER return)');
  WHILE (Response = 'Y') OR (Response = 'y') DO
  BEGIN
    write('Enter width: ');
    readln(Width);
    write('Enter height: ');
    readln(Height);
    write('Enter sample count: ');
    readln(Samples);

    { Initialise mode 13, 320x200 256 colours }
    Regs.ax := $13;
    intr($10, regs);
    
    { Make a limited-colour palette to cater for the lame 16 million to 256 colour "conversion" }
	makePalette;

    Engine_Run('image.ppm', Width, Height, Samples);

    { Wait for enter to be pressed using interrupts instead of the CRT unit, as in some versions
      of Turbo Pascal just the act of using the CRT unit causes your program to crash on startup }
    regs.ah := $00;
    intr($16, regs);

    { Go back to text mode }
    regs.ax := $03;
    intr($10, regs);

    write('Render again? (Y/N) ');
    readln(Response);
  END;
END.