// Generates Nutesia's app icons (Android, iOS, web, Play Store) from
// branding/logo_source.jpg. Standard library only:
//   cd branding && go run generate_icons.go ..
package main

import (
	"encoding/json"
	"fmt"
	"image"
	"image/color"
	"image/jpeg"
	"image/png"
	"math"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
)

type mask struct {
	w, h int
	v    []float64 // ink coverage 0..1
}

func (m *mask) at(x, y float64) float64 { // bilinear, 0 outside
	x -= 0.5
	y -= 0.5
	x0, y0 := math.Floor(x), math.Floor(y)
	fx, fy := x-x0, y-y0
	get := func(xi, yi int) float64 {
		if xi < 0 || yi < 0 || xi >= m.w || yi >= m.h {
			return 0
		}
		return m.v[yi*m.w+xi]
	}
	ix, iy := int(x0), int(y0)
	a := get(ix, iy)*(1-fx) + get(ix+1, iy)*fx
	b := get(ix, iy+1)*(1-fx) + get(ix+1, iy+1)*fx
	return a*(1-fy) + b*fy
}

var (
	src, bold   *mask // bold: strokes thickened for small icons
	cx, cy, rad float64 // logo centre and radius in source pixels
	ink         color.RGBA
)

func load(path string) {
	f, err := os.Open(path)
	check(err)
	defer f.Close()
	img, err := jpeg.Decode(f)
	check(err)
	b := img.Bounds()
	w, h := b.Dx(), b.Dy()

	// Paper colour: median red of the border. Teal ink has a much lower red
	// channel than the neutral paper, so red measures ink coverage.
	var border []float64
	red := func(x, y int) float64 {
		r, _, _, _ := img.At(b.Min.X+x, b.Min.Y+y).RGBA()
		return float64(r >> 8)
	}
	for x := 0; x < w; x++ {
		border = append(border, red(x, 0), red(x, h-1))
	}
	sort.Float64s(border)
	paper := border[len(border)/2]

	// Darkest reds are solid ink.
	var reds []float64
	for y := 0; y < h; y++ {
		for x := 0; x < w; x++ {
			reds = append(reds, red(x, y))
		}
	}
	sort.Float64s(reds)
	inkRed := reds[len(reds)/400] // 0.25th percentile

	src = &mask{w: w, h: h, v: make([]float64, w*h)}
	minX, minY, maxX, maxY := w, h, 0, 0
	var sr, sg, sb, n float64
	for y := 0; y < h; y++ {
		for x := 0; x < w; x++ {
			t := (paper - red(x, y)) / (paper - inkRed)
			// Paper grain reads as faint ink; drop it and stretch the rest.
			t = clamp((t - 0.12) / 0.80)
			src.v[y*w+x] = t
			if t > 0.5 {
				minX, minY = min(minX, x), min(minY, y)
				maxX, maxY = max(maxX, x), max(maxY, y)
			}
			if t > 0.95 {
				r, g, bb, _ := img.At(b.Min.X+x, b.Min.Y+y).RGBA()
				sr, sg, sb, n = sr+float64(r>>8), sg+float64(g>>8), sb+float64(bb>>8), n+1
			}
		}
	}
	bold = dilate(src, 1.6)
	cx, cy = float64(minX+maxX+1)/2, float64(minY+maxY+1)/2
	rad = math.Max(float64(maxX-minX+1), float64(maxY-minY+1)) / 2
	ink = color.RGBA{uint8(sr / n), uint8(sg / n), uint8(sb / n), 255}
	fmt.Printf("source %dx%d, logo centre (%.0f,%.0f) radius %.0f, ink #%02X%02X%02X\n",
		w, h, cx, cy, rad, ink.R, ink.G, ink.B)
}

// render draws the logo into a size×size square, the logo's outer ring
// spanning frac of the width. bg nil = transparent.
func render(size int, frac float64, bg *color.RGBA) image.Image {
	d := float64(size) * frac     // logo diameter in output px
	scale := 2 * rad / d          // source px per output px
	up := scale < 0.9             // enlarging: sharpen the soft edges
	ss := int(math.Ceil(scale)) + 1 // supersamples per axis when shrinking
	if up {
		ss = 2
	}
	m := src
	if d < 300 { // thin strokes vanish at launcher size
		m = bold
	}
	out := image.NewNRGBA(image.Rect(0, 0, size, size))
	half := float64(size) / 2
	for y := 0; y < size; y++ {
		for x := 0; x < size; x++ {
			var a float64
			for j := 0; j < ss; j++ {
				for i := 0; i < ss; i++ {
					px := float64(x) + (float64(i)+0.5)/float64(ss)
					py := float64(y) + (float64(j)+0.5)/float64(ss)
					v := m.at(cx+(px-half)*scale, cy+(py-half)*scale)
					if up {
						v = smoothstep(0.25, 0.75, v)
					}
					a += v
				}
			}
			a /= float64(ss * ss)
			if bg == nil {
				out.SetNRGBA(x, y, color.NRGBA{ink.R, ink.G, ink.B, uint8(math.Round(a * 255))})
				continue
			}
			mix := func(b, i uint8) uint8 { return uint8(math.Round(float64(b)*(1-a) + float64(i)*a)) }
			out.SetNRGBA(x, y, color.NRGBA{mix(bg.R, ink.R), mix(bg.G, ink.G), mix(bg.B, ink.B), 255})
		}
	}
	if bg != nil {
		// Opaque RGBA so the PNG encoder writes RGB without an alpha channel
		// (App Store rejects icons with alpha).
		rgba := image.NewRGBA(out.Bounds())
		for i := 0; i < len(out.Pix); i += 4 {
			copy(rgba.Pix[i:i+4], out.Pix[i:i+4])
		}
		return rgba
	}
	return out
}

func write(path string, img image.Image) {
	check(os.MkdirAll(filepath.Dir(path), 0o755))
	f, err := os.Create(path)
	check(err)
	check(png.Encode(f, img))
	check(f.Close())
	fmt.Println("wrote", path, img.Bounds().Dx())
}

func main() {
	root := os.Args[1]
	load(filepath.Join(root, "branding/logo_source.jpg"))
	white := &color.RGBA{255, 255, 255, 255}
	res := filepath.Join(root, "android/app/src/main/res")

	// Android: legacy square icons (pre-8.0) and adaptive foregrounds. The
	// adaptive safe zone is the central 66dp circle of 108dp, so the ring
	// stays inside 60%.
	for _, d := range []struct {
		name   string
		legacy int
	}{{"mdpi", 48}, {"hdpi", 72}, {"xhdpi", 96}, {"xxhdpi", 144}, {"xxxhdpi", 192}} {
		write(filepath.Join(res, "mipmap-"+d.name, "ic_launcher.png"), render(d.legacy, 0.86, white))
		write(filepath.Join(res, "mipmap-"+d.name, "ic_launcher_foreground.png"), render(d.legacy*108/48, 0.60, nil))
	}

	// iOS: every entry in the asset catalog, opaque.
	iosDir := filepath.Join(root, "ios/Runner/Assets.xcassets/AppIcon.appiconset")
	var contents struct {
		Images []struct{ Filename, Size, Scale string } `json:"images"`
	}
	raw, err := os.ReadFile(filepath.Join(iosDir, "Contents.json"))
	check(err)
	check(json.Unmarshal(raw, &contents))
	done := map[string]bool{}
	for _, im := range contents.Images {
		if done[im.Filename] {
			continue
		}
		done[im.Filename] = true
		pt, _ := strconv.ParseFloat(strings.Split(im.Size, "x")[0], 64)
		sc, _ := strconv.ParseFloat(strings.TrimSuffix(im.Scale, "x"), 64)
		write(filepath.Join(iosDir, im.Filename), render(int(math.Round(pt*sc)), 0.84, white))
	}

	// Web: regular icons, maskable icons (safe zone = central 80% circle), favicon.
	web := filepath.Join(root, "web")
	write(filepath.Join(web, "icons/Icon-192.png"), render(192, 0.86, white))
	write(filepath.Join(web, "icons/Icon-512.png"), render(512, 0.86, white))
	write(filepath.Join(web, "icons/Icon-maskable-192.png"), render(192, 0.72, white))
	write(filepath.Join(web, "icons/Icon-maskable-512.png"), render(512, 0.72, white))
	write(filepath.Join(web, "favicon.png"), render(32, 0.96, white))

	// Store and master copies.
	write(filepath.Join(root, "branding/play_store_icon_512.png"), render(512, 0.80, white))
	write(filepath.Join(root, "branding/icon_1024.png"), render(1024, 0.84, white))
	write(filepath.Join(root, "branding/icon_foreground_1024.png"), render(1024, 0.84, nil))
}

// dilate thickens strokes: each pixel takes the strongest ink within r px,
// fading over the last pixel so edges stay anti-aliased.
func dilate(m *mask, r float64) *mask {
	out := &mask{w: m.w, h: m.h, v: make([]float64, len(m.v))}
	ri := int(math.Ceil(r))
	for y := 0; y < m.h; y++ {
		for x := 0; x < m.w; x++ {
			best := 0.0
			for dy := -ri; dy <= ri; dy++ {
				for dx := -ri; dx <= ri; dx++ {
					xx, yy := x+dx, y+dy
					if xx < 0 || yy < 0 || xx >= m.w || yy >= m.h {
						continue
					}
					w := clamp(r + 1 - math.Hypot(float64(dx), float64(dy)))
					best = math.Max(best, m.v[yy*m.w+xx]*w)
				}
			}
			out.v[y*m.w+x] = best
		}
	}
	return out
}

func clamp(v float64) float64 { return math.Max(0, math.Min(1, v)) }

func smoothstep(e0, e1, x float64) float64 {
	t := clamp((x - e0) / (e1 - e0))
	return t * t * (3 - 2*t)
}

func check(err error) {
	if err != nil {
		panic(err)
	}
}
