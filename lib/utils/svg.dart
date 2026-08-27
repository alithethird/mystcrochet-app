String substituteColors(String svg, String fgColor, String bgColor) {
  return svg
      .replaceAll('#000000', fgColor)
      .replaceAll('#ffffff', bgColor);
}

SvgDimensions svgDimensions(String svg) {
  final wReg = RegExp(r'width="(\d+(?:\.\d+)?)"');
  final hReg = RegExp(r'height="(\d+(?:\.\d+)?)"');
  final wMatch = wReg.firstMatch(svg);
  final hMatch = hReg.firstMatch(svg);
  final w = wMatch != null ? double.parse(wMatch.group(1)!) : 32.0;
  final h = hMatch != null ? double.parse(hMatch.group(1)!) : 32.0;
  return SvgDimensions(w: w, h: h);
}

class SvgDimensions {
  final double w;
  final double h;
  SvgDimensions({required this.w, required this.h});
}