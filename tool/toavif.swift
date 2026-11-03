import ImageIO
import Foundation
import UniformTypeIdentifiers
let args = CommandLine.arguments
let q = Double(args[1])!
for i in 2..<args.count {
  let inp = URL(fileURLWithPath: args[i])
  let out = inp.deletingPathExtension().appendingPathExtension("avif")
  guard let src = CGImageSourceCreateWithURL(inp as CFURL, nil), let img = CGImageSourceCreateImageAtIndex(src, 0, nil) else { print("read fail \(args[i])"); continue }
  guard let dst = CGImageDestinationCreateWithURL(out as CFURL, "public.avif" as CFString, 1, nil) else { print("dest fail"); continue }
  CGImageDestinationAddImage(dst, img, [kCGImageDestinationLossyCompressionQuality: q] as CFDictionary)
  if !CGImageDestinationFinalize(dst) { print("finalize fail \(args[i])") }
}
