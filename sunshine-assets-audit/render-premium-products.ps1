$srcDir = "C:\xampp\htdocs\sunshine-assets-audit"
$outDir = "C:\xampp\htdocs\sunshine-assets-audit\products-premium"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$base = "C:\Program Files\WindowsApps\Microsoft.PowerShell_7.6.1.0_x64__8wekyb3d8bbwe"
$refs = @(
    "$base\System.Drawing.Common.dll",
    "$base\System.Drawing.dll",
    "$base\System.Drawing.Primitives.dll",
    "$base\System.Private.Windows.GdiPlus.dll",
    "$base\System.Private.Windows.Core.dll",
    "$base\System.Private.CoreLib.dll",
    "$base\System.Runtime.dll",
    "$base\System.Collections.dll"
)

Add-Type -ReferencedAssemblies $refs -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;

public static class ProductPremiumRenderer
{
    struct Rgb
    {
        public byte R, G, B;
        public Rgb(byte r, byte g, byte b) { R = r; G = g; B = b; }
    }

    static double Brightness(Rgb c) => (0.299 * c.R + 0.587 * c.G + 0.114 * c.B);

    static double Saturation(Rgb c)
    {
        double max = Math.Max(c.R, Math.Max(c.G, c.B));
        double min = Math.Min(c.R, Math.Min(c.G, c.B));
        if (max <= 0.0) return 0.0;
        return (max - min) / max;
    }

    static double Dist(Rgb a, Rgb b)
    {
        int dr = a.R - b.R, dg = a.G - b.G, db = a.B - b.B;
        return Math.Sqrt(dr * dr + dg * dg + db * db);
    }

    static Rgb GetPixel(byte[] data, int stride, int x, int y)
    {
        int i = y * stride + x * 4;
        return new Rgb(data[i + 2], data[i + 1], data[i]);
    }

    static Rgb RowEdgeAverage(byte[] data, int stride, int w, int y)
    {
        int n = Math.Min(18, Math.Max(1, w / 20));
        long r = 0, g = 0, b = 0, count = 0;
        for (int x = 0; x < n; x++)
        {
            var c = GetPixel(data, stride, x, y);
            r += c.R; g += c.G; b += c.B; count++;
        }
        for (int x = w - n; x < w; x++)
        {
            var c = GetPixel(data, stride, x, y);
            r += c.R; g += c.G; b += c.B; count++;
        }
        return new Rgb((byte)(r / count), (byte)(g / count), (byte)(b / count));
    }

    static bool IsStrongForeground(Rgb c)
    {
        double br = Brightness(c);
        double sat = Saturation(c);
        return br < 86 || (sat > 0.22 && br > 35) || (Math.Abs(c.R - c.G) + Math.Abs(c.G - c.B) + Math.Abs(c.R - c.B) > 80 && br > 45);
    }

    static bool IsBackgroundCandidate(Rgb c, Rgb rowBg)
    {
        double br = Brightness(c);
        double sat = Saturation(c);
        double dist = Dist(c, rowBg);
        if (br < 70) return false;
        if (sat < 0.20 && dist < 82) return true;
        if (sat < 0.12 && br > 150 && dist < 105) return true;
        return false;
    }

    static Color AdjustProductColor(Rgb c)
    {
        double contrast = 1.08;
        int r = Clamp((int)((c.R - 128) * contrast + 128 + 5));
        int g = Clamp((int)((c.G - 128) * contrast + 128 + 5));
        int b = Clamp((int)((c.B - 128) * contrast + 128 + 5));
        return Color.FromArgb(255, r, g, b);
    }

    static int Clamp(int v) => v < 0 ? 0 : (v > 255 ? 255 : v);

    static void FillPremiumBackground(Graphics g, int w, int h)
    {
        using (var bg = new LinearGradientBrush(new Rectangle(0, 0, w, h), Color.FromArgb(250, 247, 240), Color.FromArgb(235, 225, 210), LinearGradientMode.Vertical))
            g.FillRectangle(bg, 0, 0, w, h);

        using (var glow = new GraphicsPath())
        {
            glow.AddEllipse(-w / 3, -h / 7, w * 5 / 3, h * 2 / 5);
            using (var pgb = new PathGradientBrush(glow))
            {
                pgb.CenterColor = Color.FromArgb(64, 255, 255, 255);
                pgb.SurroundColors = new[] { Color.FromArgb(0, 255, 255, 255) };
                g.FillPath(pgb, glow);
            }
        }

        using (var leafBrush = new SolidBrush(Color.FromArgb(16, 47, 107, 69)))
        {
            g.TranslateTransform(w - 150, 110);
            g.RotateTransform(-22);
            for (int i = 0; i < 5; i++) g.FillEllipse(leafBrush, i * 28, i * 36, 130, 42);
            g.ResetTransform();

            g.TranslateTransform(70, h - 360);
            g.RotateTransform(20);
            for (int i = 0; i < 5; i++) g.FillEllipse(leafBrush, i * 24, i * 44, 125, 40);
            g.ResetTransform();
        }

        using (var linePen = new Pen(Color.FromArgb(28, 200, 164, 93), 2f))
        {
            g.DrawLine(linePen, 112, 132, w - 112, 132);
            g.DrawLine(linePen, 112, h - 132, w - 112, h - 132);
        }
    }

    static void DrawShadow(Graphics g, int cx, int cy, int width)
    {
        using (var path = new GraphicsPath())
        {
            path.AddEllipse(cx - width / 2, cy - width / 8, width, width / 4);
            using (var pgb = new PathGradientBrush(path))
            {
                pgb.CenterColor = Color.FromArgb(82, 37, 32, 24);
                pgb.SurroundColors = new[] { Color.FromArgb(0, 37, 32, 24) };
                g.FillPath(pgb, path);
            }
        }
    }

    public static void Render(string inputPath, string outputPath)
    {
        const int TW = 1024;
        const int TH = 1536;
        using (var srcOriginal = new Bitmap(inputPath))
        using (var src = new Bitmap(srcOriginal.Width, srcOriginal.Height, PixelFormat.Format32bppArgb))
        {
            using (var sg = Graphics.FromImage(src)) sg.DrawImage(srcOriginal, 0, 0, src.Width, src.Height);
            int w = src.Width, h = src.Height;
            var rect = new Rectangle(0, 0, w, h);
            var bits = src.LockBits(rect, ImageLockMode.ReadOnly, PixelFormat.Format32bppArgb);
            int stride = bits.Stride;
            byte[] data = new byte[Math.Abs(stride) * h];
            System.Runtime.InteropServices.Marshal.Copy(bits.Scan0, data, 0, data.Length);
            src.UnlockBits(bits);

            var rowBgs = new Rgb[h];
            for (int y = 0; y < h; y++) rowBgs[y] = RowEdgeAverage(data, stride, w, y);

            bool[] bg = new bool[w * h];
            int[] q = new int[w * h];
            int head = 0;
            int tail = 0;
            Action<int, int> TrySeed = (x, y) => {
                var c = GetPixel(data, stride, x, y);
                int idx = y * w + x;
                if (!bg[idx] && IsBackgroundCandidate(c, rowBgs[y])) { bg[idx] = true; q[tail++] = idx; }
            };
            for (int x = 0; x < w; x++) { TrySeed(x, 0); TrySeed(x, h - 1); }
            for (int y = 0; y < h; y++) { TrySeed(0, y); TrySeed(w - 1, y); }

            int[] dx = { 1, -1, 0, 0 };
            int[] dy = { 0, 0, 1, -1 };
            while (head < tail)
            {
                int idx = q[head++];
                int x = idx % w, y = idx / w;
                for (int k = 0; k < 4; k++)
                {
                    int nx = x + dx[k], ny = y + dy[k];
                    if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
                    int nidx = ny * w + nx;
                    if (bg[nidx]) continue;
                    var c = GetPixel(data, stride, nx, ny);
                    if (IsBackgroundCandidate(c, rowBgs[ny])) { bg[nidx] = true; q[tail++] = nidx; }
                }
            }

            int minX = w, minY = h, maxX = 0, maxY = 0;
            for (int y = 0; y < h; y += 2)
            {
                for (int x = 0; x < w; x += 2)
                {
                    var c = GetPixel(data, stride, x, y);
                    if (IsStrongForeground(c))
                    {
                        if (x < minX) minX = x;
                        if (x > maxX) maxX = x;
                        if (y < minY) minY = y;
                        if (y > maxY) maxY = y;
                    }
                }
            }

            if (minX >= maxX || minY >= maxY)
            {
                minX = w / 4; maxX = w * 3 / 4; minY = h / 4; maxY = h * 7 / 8;
            }

            int strongMinX = minX;
            int strongMinY = minY;
            int strongMaxX = maxX;
            int strongMaxY = maxY;
            int bw = maxX - minX + 1;
            int bh = maxY - minY + 1;
            int protectCx = (strongMinX + strongMaxX) / 2;
            int protectHalfW = Math.Max(95, (int)(bw * 0.92));
            int protectMinX = Math.Max(0, protectCx - protectHalfW);
            int protectMaxX = Math.Min(w - 1, protectCx + protectHalfW);
            int protectMinY = Math.Max(0, strongMinY - Math.Max(180, (int)(bh * 1.20)));
            int protectMaxY = Math.Min(h - 1, strongMaxY + Math.Max(180, (int)(bh * 0.90)));
            int expandX = Math.Max(70, (int)(bw * 0.42));
            int expandTop = Math.Max(95, (int)(bh * 0.42));
            int expandBottom = Math.Max(90, (int)(bh * 0.28));
            if (bh < h * 0.42)
            {
                expandX = Math.Max(expandX, (int)(bw * 0.85));
                expandTop = Math.Max(expandTop, (int)(bh * 1.20));
                expandBottom = Math.Max(expandBottom, (int)(bh * 0.70));
            }

            minX = Math.Max(0, minX - expandX);
            maxX = Math.Min(w - 1, maxX + expandX);
            minY = Math.Max(0, minY - expandTop);
            maxY = Math.Min(h - 1, maxY + expandBottom);

            int cropW = maxX - minX + 1;
            int cropH = maxY - minY + 1;
            using (var cutout = new Bitmap(cropW, cropH, PixelFormat.Format32bppArgb))
            {
                for (int y = minY; y <= maxY; y++)
                {
                    for (int x = minX; x <= maxX; x++)
                    {
                        int idx = y * w + x;
                        var c = GetPixel(data, stride, x, y);
                        bool strong = IsStrongForeground(c);
                        bool protectedWhite =
                            x >= protectMinX && x <= protectMaxX &&
                            y >= protectMinY && y <= protectMaxY &&
                            Saturation(c) < 0.20 &&
                            Brightness(c) > 125 &&
                            (Dist(c, rowBgs[y]) > 18 || Brightness(c) - Brightness(rowBgs[y]) > 10);
                        bool keep = strong || protectedWhite;
                        if (!keep) continue;
                        if (!strong && !protectedWhite && Saturation(c) < 0.12 && Dist(c, rowBgs[y]) < 58 && Brightness(c) > 105) continue;
                        cutout.SetPixel(x - minX, y - minY, AdjustProductColor(c));
                    }
                }

                int alphaMinX = cropW, alphaMinY = cropH, alphaMaxX = 0, alphaMaxY = 0;
                for (int ay = 0; ay < cropH; ay++)
                {
                    for (int ax = 0; ax < cropW; ax++)
                    {
                        if (cutout.GetPixel(ax, ay).A == 0) continue;
                        if (ax < alphaMinX) alphaMinX = ax;
                        if (ax > alphaMaxX) alphaMaxX = ax;
                        if (ay < alphaMinY) alphaMinY = ay;
                        if (ay > alphaMaxY) alphaMaxY = ay;
                    }
                }

                if (alphaMinX >= alphaMaxX || alphaMinY >= alphaMaxY)
                {
                    alphaMinX = 0; alphaMinY = 0; alphaMaxX = cropW - 1; alphaMaxY = cropH - 1;
                }

                int pad = 26;
                alphaMinX = Math.Max(0, alphaMinX - pad);
                alphaMinY = Math.Max(0, alphaMinY - pad);
                alphaMaxX = Math.Min(cropW - 1, alphaMaxX + pad);
                alphaMaxY = Math.Min(cropH - 1, alphaMaxY + pad);
                Rectangle subjectRect = new Rectangle(alphaMinX, alphaMinY, alphaMaxX - alphaMinX + 1, alphaMaxY - alphaMinY + 1);
                using (var subject = cutout.Clone(subjectRect, PixelFormat.Format32bppArgb))
                using (var output = new Bitmap(TW, TH, PixelFormat.Format24bppRgb))
                using (var g = Graphics.FromImage(output))
                {
                    g.SmoothingMode = SmoothingMode.HighQuality;
                    g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                    g.PixelOffsetMode = PixelOffsetMode.HighQuality;
                    g.CompositingQuality = CompositingQuality.HighQuality;
                    FillPremiumBackground(g, TW, TH);

                    double scale = Math.Min(620.0 / subject.Width, 1030.0 / subject.Height);
                    int drawW = Math.Max(1, (int)Math.Round(subject.Width * scale));
                    int drawH = Math.Max(1, (int)Math.Round(subject.Height * scale));
                    int drawX = (TW - drawW) / 2;
                    int baseline = 1260;
                    int drawY = baseline - drawH;
                    if (drawY < 250) drawY = 250;

                    DrawShadow(g, TW / 2, Math.Min(1320, drawY + drawH - 22), Math.Max(310, (int)(drawW * 0.78)));
                    g.DrawImage(subject, new Rectangle(drawX, drawY, drawW, drawH));

                    var codec = Array.Find(ImageCodecInfo.GetImageEncoders(), e => e.MimeType == "image/jpeg");
                    using (var ep = new EncoderParameters(1))
                    {
                        ep.Param[0] = new EncoderParameter(System.Drawing.Imaging.Encoder.Quality, 94L);
                        output.Save(outputPath, codec, ep);
                    }
                }
            }
        }
    }
}
'@

Get-ChildItem -Path $srcDir -Filter "product-*.jpg" | Sort-Object Name | ForEach-Object {
    $outFile = Join-Path $outDir $_.Name
    [ProductPremiumRenderer]::Render($_.FullName, $outFile)
    Write-Output "$($_.Name) -> premium"
}
