//
//  File.swift
//
//
//  Created by William Vabrinskas on 1/22/22.
//

import Foundation
import Accelerate

public extension Array where Element == [Double] {
  
  func zeroPad(filterSize: (Int, Int), stride: (Int, Int) = (1,1)) -> Self {
    guard let first = self.first else {
      return self
    }
    
    let height = Double(self.count)
    let width = Double(first.count)
    
    let outHeight = ceil(height / Double(stride.0))
    let outWidth = ceil(width / Double(stride.1))
    
    let padAlongHeight = Swift.max((outHeight - 1) * Double(stride.0) + Double(filterSize.0) - height, 0)
    let padAlongWidth = Swift.max((outWidth - 1) * Double(stride.1) + Double(filterSize.1) - width, 0)

    let paddingTop = Int(floor(padAlongHeight / 2))
    let paddingBottom = Int(padAlongHeight - Double(paddingTop))
    let paddingLeft = Int(floor(padAlongWidth / 2))
    let paddingRight = Int(padAlongWidth - Double(paddingLeft))
    
    var result: [Element] = self
    let newRow = [Double](repeating: 0, count: first.count)
    
    //top / bottom comes first so we can match row insertion
    for _ in 0..<paddingTop {
      result.insert(newRow, at: 0)
    }
    
    for _ in 0..<paddingBottom {
      result.append(newRow)
    }
    
    var paddingLeftMapped: [[Double]] = []
    result.forEach { v in
      var row = v
      for _ in 0..<paddingLeft {
        row.insert(0, at: 0)
      }
      paddingLeftMapped.append(row)
    }
    
    result = paddingLeftMapped
    
    var paddingRightMapped: [[Double]] = []
    
    result.forEach { v in
      var row = v
      for _ in 0..<paddingRight {
        row.append(0)
      }
      paddingRightMapped.append(row)
    }
    
    result = paddingRightMapped
    
    return result
  }
  
  func zeroPad() -> Self {
    guard let first = self.first else {
      return self
    }
    
    let result: [Element] = self

    let mapped = result.map { r -> [Double] in
      var newR: [Double] = [0]
      newR.append(contentsOf: r)
      newR.append(0)
      return newR
    }
    
    let zeros = [Double](repeating: 0, count: first.count + 2)
    var r = [zeros]
    r.append(contentsOf: mapped)
    r.append(zeros)
        
    return r
  }

  func transConv2d(_ filter: [[Double]],
                   strides: (rows: Int, columns: Int) = (1,1),
                   padding: NumSwift.ConvPadding = .valid,
                   filterSize: (rows: Int, columns: Int),
                   inputSize: (rows: Int, columns: Int)) -> Element {
    
    let result: Element = NumSwift.transConv2D(signal: self,
                                               filter: filter,
                                               strides: strides,
                                               padding: padding,
                                               filterSize: filterSize,
                                               inputSize: inputSize).flatten()
      
    return result
  }
  
  func flip180() -> Self {
    self.reversed().map { $0.reverse() }
  }
}

public extension Array where Element == [Float] {

  func zeroPad(padding: NumSwiftPadding) -> Self {
    guard let first = self.first else {
      return self
    }
    
    let paddingTop = padding.top
    let paddingLeft = padding.left
    let paddingRight = padding.right
    let paddingBottom = padding.bottom
    
    var result: [Element] = self
    let newRow = [Float](repeating: 0, count: first.count)
    
    //top / bottom comes first so we can match row insertion
    for _ in 0..<paddingTop {
      result.insert(newRow, at: 0)
    }
    
    for _ in 0..<paddingBottom {
      result.append(newRow)
    }
    
    var paddingLeftMapped: [[Float]] = []
    result.forEach { v in
      var row = v
      for _ in 0..<paddingLeft {
        row.insert(0, at: 0)
      }
      paddingLeftMapped.append(row)
    }
    
    result = paddingLeftMapped
    
    var paddingRightMapped: [[Float]] = []
    
    result.forEach { v in
      var row = v
      for _ in 0..<paddingRight {
        row.append(0)
      }
      paddingRightMapped.append(row)
    }
    
    result = paddingRightMapped
    
    return result
  }
  
  func stridePad(strides: (rows: Int, columns: Int), shrink: Int = 0) -> Self {
    var result = NumSwiftC.stridePad(signal: self, strides: strides)
    result = result.shrink(by: shrink)
    return result
  }
  
  func stridePad(strides: (rows: Int, columns: Int), padding: Int = 0) -> Self {
    var result = NumSwiftC.stridePad(signal: self, strides: strides)

    for _ in 0..<padding {
      result = NumSwiftC.zeroPad(signal: result, padding: NumSwiftPadding(top: 1,
                                                                          left: 1,
                                                                          right: 1,
                                                                          bottom: 1))
    }
    
    return result
  }
  
  func zeroPad(filterSize: (Int, Int), stride: (Int, Int) = (1,1)) -> Self {
    guard let first = self.first else {
      return self
    }
    
    let height = Double(self.count)
    let width = Double(first.count)
    
    let outHeight = ceil(height / Double(stride.0))
    let outWidth = ceil(width / Double(stride.1))
    
    let padAlongHeight = Swift.max((outHeight - 1) * Double(stride.0) + Double(filterSize.0) - height, 0)
    let padAlongWidth = Swift.max((outWidth - 1) * Double(stride.1) + Double(filterSize.1) - width, 0)

    let paddingTop = Int(floor(padAlongHeight / 2))
    let paddingBottom = Int(padAlongHeight - Double(paddingTop))
    let paddingLeft = Int(floor(padAlongWidth / 2))
    let paddingRight = Int(padAlongWidth - Double(paddingLeft))
        
    let paddingObc = NumSwiftPadding(top: paddingTop,
                                     left: paddingLeft,
                                     right: paddingRight,
                                     bottom: paddingBottom)
    
    return self.zeroPad(padding: paddingObc)
  }

  func zeroPad() -> Self {
    guard let first = self.first else {
      return self
    }
    
    let result: [Element] = self

    let mapped = result.map { r -> [Float] in
      var newR: [Float] = [0]
      newR.append(contentsOf: r)
      newR.append(0)
      return newR
    }
    
    let zeros = [Float](repeating: 0, count: first.count + 2)
    var r = [zeros]
    r.append(contentsOf: mapped)
    r.append(zeros)
        
    return r
  }
  
  func shrink(by size: Int) -> Self {
    var results: [[Float]] = self
    
    for _ in 0..<size {
      var newResult: [[Float]] = []
        
      results.forEach { p in
        var newRow: [Float] = p
        newRow.removeFirst()
        newRow.removeLast()
        newResult.append(newRow)
      }
      
      results = newResult
      results.removeFirst()
      results.removeLast()
    }
    
    return results
  }
  
  func stridePad(strides: (rows: Int, columns: Int)) -> Self {
    NumSwiftC.stridePad(signal: self, strides: strides)
  }
  
  func transConv2d(_ filter: [[Float]],
                   strides: (rows: Int, columns: Int) = (1,1),
                   padding: NumSwift.ConvPadding = .valid,
                   filterSize: (rows: Int, columns: Int),
                   inputSize: (rows: Int, columns: Int)) -> Element {
    
    let result: Element = NumSwift.transConv2D(signal: self,
                                               filter: filter,
                                               strides: strides,
                                               padding: padding,
                                               filterSize: filterSize,
                                               inputSize: inputSize).flatten()
      
    return result
  }

  func flip180() -> Self {
    self.reversed().map { $0.reverse() }
  }
}

//use accelerate
public extension Array where Element == Float {
  var sum: Element {
    vDSP.sum(self)
  }
  
  var sumOfSquares: Element {
    let stride = vDSP_Stride(1)
    let n = vDSP_Length(self.count)
    
    var c: Element = .nan
    
    vDSP_svesq(self,
               stride,
               &c,
               n)
    return c
  }
  
  var indexOfMin: (UInt, Element) {
    vDSP.indexOfMinimum(self)
  }
  
  var indexOfMax: (UInt, Element) {
    vDSP.indexOfMaximum(self)
  }
  
  var max: Element {
    vDSP.maximum(self)
  }
  
  var min: Element {
    vDSP.minimum(self)
  }
  
  var mean: Element {
    vDSP.mean(self)
  }
  
  mutating func fillZeros() {
    vDSP.fill(&self, with: .zero)
  }
  
  @inlinable mutating func clip(_ to: Element) {
    self = self.map { Swift.max(-to, Swift.min(to, $0)) }
  }
  
  @inlinable mutating func l1Normalize(limit: Element) {
    //normalize gradients
    let norm = self.sum
    if norm > limit {
      self = self / norm
    }
  }
  
  /// Will normalize the vector using the L2 norm to 1.0 if the sum of squares is greater than the limit
  /// - Parameter limit: the sumOfSquares limit that when reached it should normalize
  @inlinable mutating func l2Normalize(limit: Element) {
    //normalize gradients
    let norm = self.sumOfSquares
    if norm > limit {
      let length = sqrt(norm)
      self = self / length
    }
  }
  
  /// Normalizes input to have 0 mean and 1 unit standard deviation
  @discardableResult
  @inlinable mutating func normalize() -> (mean: Element, std: Element) {
    var mean: Float = 0
    var std: Float = 0
    var result: [Float] = [Float](repeating: 0, count: self.count)
    vDSP_normalize(self,
                   vDSP_Stride(1),
                   &result,
                   vDSP_Stride(1),
                   &mean,
                   &std,
                   vDSP_Length(self.count))
    self = result
    return (mean, std)
  }
  
  func reverse() -> Self {
    var result = self
    vDSP.reverse(&result)
    return result
  }
  
  func dot(_ b: [Element]) -> Element {
    let n = vDSP_Length(self.count)
    var C: Element = .nan
    
    let aStride = vDSP_Stride(1)
    let bStride = vDSP_Stride(1)
    
    vDSP_dotpr(self,
               aStride,
               b,
               bStride,
               &C,
               n)
    
    return C
  }
  
  func multiply(B: [Element], columns: Int32, rows: Int32, dimensions: Int32 = 1) -> [Element] {
    let M = vDSP_Length(dimensions)
    let N = vDSP_Length(columns)
    let K = vDSP_Length(rows)
    
    var C: [Element] = [Element].init(repeating: 0, count: Int(N))
    
    let aStride = vDSP_Stride(1)
    let bStride = vDSP_Stride(1)
    let cStride = vDSP_Stride(1)
    
    vDSP_mmul(self,
              aStride,
              B,
              bStride,
              &C,
              cStride,
              vDSP_Length(M),
              vDSP_Length(N),
              vDSP_Length(K))
    
    return C
  }
  
  func transpose(columns: Int, rows: Int) -> [Element] {
    var result: [Element] = [Element].init(repeating: 0, count: columns * rows)
    
    vDSP_mtrans(self,
                vDSP_Stride(1),
                &result,
                vDSP_Stride(1),
                vDSP_Length(columns),
                vDSP_Length(rows))
    
    return result
  }
  
  static func +(lhs: [Element], rhs: Element) -> [Element] {
    return vDSP.add(rhs, lhs)
  }
  
  static func +(lhs: Element, rhs: [Element]) -> [Element] {
    return vDSP.add(lhs, rhs)
  }
  
  static func +(lhs: [Element], rhs: [Element]) -> [Element] {
    return vDSP.add(rhs, lhs)
  }
  
  static func -(lhs: [Element], rhs: [Element]) -> [Element] {
    return vDSP.subtract(lhs, rhs)
  }
  
  static func *(lhs: [Element], rhs: Element) -> [Element] {
    return vDSP.multiply(rhs, lhs)
  }
  
  static func *(lhs: Element, rhs: [Element]) -> [Element] {
    return vDSP.multiply(lhs, rhs)
  }
  
  static func *(lhs: [Element], rhs: [Element]) -> [Element] {
    return vDSP.multiply(lhs, rhs)
  }
  
  static func /(lhs: [Element], rhs: [Element]) -> [Element] {
    return vDSP.divide(lhs, rhs)
  }
  
  static func /(lhs: [Element], rhs: Element) -> [Element] {
    return vDSP.divide(lhs, rhs)
  }
  
}

//use accelerate
public extension Array where Element == Double {
  var sum: Element {
    vDSP.sum(self)
  }
  
  var sumOfSquares: Element {
    let stride = vDSP_Stride(1)
    let n = vDSP_Length(self.count)
    
    var c: Element = .nan
    
    vDSP_svesqD(self,
                stride,
                &c,
                n)
    return c
  }
  
  var indexOfMin: (UInt, Element) {
    vDSP.indexOfMinimum(self)
  }
  
  var indexOfMax: (UInt, Element) {
    vDSP.indexOfMaximum(self)
  }
  
  var mean: Element {
    vDSP.mean(self)
  }
  
  var max: Element {
    vDSP.maximum(self)
  }
  
  var min: Element {
    vDSP.minimum(self)
  }
  
  @inlinable mutating func clip(_ to: Element) {
    self = self.map { Swift.max(-to, Swift.min(to, $0)) }
  }
  
  @inlinable mutating func l1Normalize(limit: Element) {
    //normalize gradients
    let norm = self.sum
    if norm > limit {
      self = self / norm
    }
  }
  
  /// Will normalize the vector using the L2 norm to 1.0 if the sum of squares is greater than the limit
  /// - Parameter limit: the sumOfSquares limit that when reached it should normalize
  @inlinable mutating func l2Normalize(limit: Element) {
    //normalize gradients
    let norm = self.sumOfSquares
    if norm > limit {
      let length = sqrt(norm)
      self = self / length
    }
  }
  
  /// Normalizes input to have 0 mean and 1 unit standard deviation
  @discardableResult
  @inlinable mutating func normalize() -> (mean: Element, std: Element) {
    var mean: Element = 0
    var std: Element = 0
    var result: [Element] = [Element](repeating: 0, count: self.count)
    vDSP_normalizeD(self,
                   vDSP_Stride(1),
                   &result,
                   vDSP_Stride(1),
                   &mean,
                   &std,
                   vDSP_Length(self.count))
    self = result
    return (mean, std)
  }
  
  func reverse() -> Self {
    var result = self
    vDSP.reverse(&result)
    return result
  }

  mutating func fillZeros() {
    vDSP.fill(&self, with: .zero)
  }
  
  func dot(_ b: [Element]) -> Element {
    let n = vDSP_Length(self.count)
    var C: Element = .nan
    
    let aStride = vDSP_Stride(1)
    let bStride = vDSP_Stride(1)
    
    vDSP_dotprD(self,
                aStride,
                b,
                bStride,
                &C,
                n)
    
    return C
  }
  
  func multiply(B: [Element], columns: Int32, rows: Int32, dimensions: Int32 = 1) -> [Element] {
    let M = vDSP_Length(dimensions)
    let N = vDSP_Length(columns)
    let K = vDSP_Length(rows)
    
    var C: [Element] = [Element].init(repeating: 0, count: Int(N))
    
    let aStride = vDSP_Stride(1)
    let bStride = vDSP_Stride(1)
    let cStride = vDSP_Stride(1)
    
    vDSP_mmulD(self,
               aStride,
               B,
               bStride,
               &C,
               cStride,
               vDSP_Length(M),
               vDSP_Length(N),
               vDSP_Length(K))
    
    return C
  }
  
  func transpose(columns: Int, rows: Int) -> [Element] {
    var result: [Element] = [Element].init(repeating: 0, count: columns * rows)
    
    vDSP_mtransD(self,
                 vDSP_Stride(1),
                 &result,
                 vDSP_Stride(1),
                 vDSP_Length(columns),
                 vDSP_Length(rows))
    
    return result
  }
  
  static func +(lhs: [Element], rhs: Element) -> [Element] {
    return vDSP.add(rhs, lhs)
  }
  
  static func +(lhs: Element, rhs: [Element]) -> [Element] {
    return vDSP.add(lhs, rhs)
  }
  
  static func +(lhs: [Element], rhs: [Element]) -> [Element] {
    return vDSP.add(rhs, lhs)
  }
  
  static func -(lhs: [Element], rhs: [Element]) -> [Element] {
    return vDSP.subtract(lhs, rhs)
  }
  
  static func *(lhs: [Element], rhs: Element) -> [Element] {
    return vDSP.multiply(rhs, lhs)
  }
  
  static func *(lhs: Element, rhs: [Element]) -> [Element] {
    return vDSP.multiply(lhs, rhs)
  }
  
  static func *(lhs: [Element], rhs: [Element]) -> [Element] {
    return vDSP.multiply(lhs, rhs)
  }
  
  static func /(lhs: [Element], rhs: [Element]) -> [Element] {
    return vDSP.divide(lhs, rhs)
  }
  
  static func /(lhs: [Element], rhs: Element) -> [Element] {
    return vDSP.divide(lhs, rhs)
  }
  
  static func /(lhs: Element, rhs: [Element]) -> [Element] {
    return vDSP.divide(rhs, lhs)
  }
}

public extension Array where Element: Equatable & Numeric & FloatingPoint {
  
  var average: Element {
    let sum = self.sumSlow
    return sum / Element(self.count)
  }
  
  func scale(_ range: ClosedRange<Element> = 0...1) -> [Element] {
    let max = self.max() ?? 0
    let min = self.min() ?? 0
    let b = range.upperBound
    let a = range.lowerBound
    
    let new =  self.map { x -> Element in
      let ba = (b - a)
      let numerator = x - min
      let denominator = max - min
      
      return ba * (numerator / denominator) + a
    }
    return new
  }
  
  func scale(from range: ClosedRange<Element> = 0...1,
             to toRange: ClosedRange<Element> = 0...1) -> [Element] {
    
    let max = range.upperBound
    let min = range.lowerBound
    
    let b = toRange.upperBound
    let a = toRange.lowerBound
    
    let new =  self.map { x -> Element in
      let ba = (b - a)
      let numerator = x - min
      let denominator = max - min
      
      return ba * (numerator / denominator) + a
    }
    return new
  }
  
  static func -(lhs: [Element], rhs: Element) -> [Element] {
    return lhs.map({ $0 - rhs })
  }
  
  static func -(lhs: Element, rhs: [Element]) -> [Element] {
    return rhs.map({ lhs - $0 })
  }
}

public extension Array where Element == [[Double]] {
  static func *(lhs: Self, rhs: Self) -> Self {
    let left = lhs
    let right = rhs
    
    let leftShape = left.shape
    let rightShape = right.shape
    
    precondition(leftShape == rightShape)
    
    let depth = leftShape[safe: 2] ?? 0
    let rows = leftShape[safe: 1] ?? 0
    
    var result: Self = []
    for d in 0..<depth {
      var new2d: Element = []
      for r in 0..<rows {
        new2d.append(left[d][r] * right[d][r])
      }
      result.append(new2d)
    }
    
    return result
  }
  
  static func /(lhs: Self, rhs: Self) -> Self {
    let left = lhs
    let right = rhs
    
    let leftShape = left.shape
    let rightShape = right.shape
    
    precondition(leftShape == rightShape)
    
    let depth = leftShape[safe: 2] ?? 0
    let rows = leftShape[safe: 1] ?? 0
    
    var result: Self = []
    for d in 0..<depth {
      var new2d: Element = []
      for r in 0..<rows {
        new2d.append(left[d][r] / right[d][r])
      }
      result.append(new2d)
    }
    
    return result
  }
  
  static func -(lhs: Self, rhs: Self) -> Self {
    let left = lhs
    let right = rhs
    
    let leftShape = left.shape
    let rightShape = right.shape
    
    precondition(leftShape == rightShape)
    
    let depth = leftShape[safe: 2] ?? 0
    let rows = leftShape[safe: 1] ?? 0
    
    var result: Self = []
    for d in 0..<depth {
      var new2d: Element = []
      for r in 0..<rows {
        new2d.append(left[d][r] - right[d][r])
      }
      result.append(new2d)
    }
    
    return result
  }
  
  static func +(lhs: Self, rhs: Self) -> Self {
    let left = lhs
    let right = rhs
    
    let leftShape = left.shape
    let rightShape = right.shape
    
    precondition(leftShape == rightShape)
    
    let depth = leftShape[safe: 2] ?? 0
    let rows = leftShape[safe: 1] ?? 0
    
    var result: Self = []
    for d in 0..<depth {
      var new2d: Element = []
      for r in 0..<rows {
        new2d.append(left[d][r] + right[d][r])
      }
      result.append(new2d)
    }
    return result
  }
}


public extension Array where Element == [[Float]] {
  var sumOfSquares: Float {
    var result: Float = 0
    self.forEach { a in
      a.forEach { b in
        let stride = vDSP_Stride(1)
        let n = vDSP_Length(b.count)
        
        var c: Float = .nan
        
        vDSP_svesq(b,
                   stride,
                   &c,
                   n)
        
        result += c
      }
    }

    return result
  }
  
  var mean: Float {
    var r: Float = 0
    var total = 0
    self.forEach { a in
      a.forEach { b in
        r += b.mean
        total += 1
      }
    }
    
    return r / Float(total)
  }
  
  var sum: Float {
    var r: Float = 0
    self.forEach { a in
      a.forEach { b in
        r += b.sum
      }
    }
    
    return r
  }
  
  static func *(lhs: Self, rhs: Float) -> Self {
    let left = lhs
            
    var result: Self = []
    for d in 0..<lhs.count {
      let new2d: Element = left[d].map { $0 * rhs }
      result.append(new2d)
    }
    
    return result
  }
  
  static func *(lhs: Float, rhs: Self) -> Self {
    var result: Self = []
    for d in 0..<rhs.count {
      let new2d: Element = rhs[d].map { $0 * lhs }
      result.append(new2d)
    }
    
    return result
  }
  
  static func /(lhs: Self, rhs: Float) -> Self {
    let left = lhs
            
    var result: Self = []
    for d in 0..<lhs.count {
      let new2d: Element = left[d].map { $0 / rhs }
      result.append(new2d)
    }
    
    return result
  }
  
  static func +(lhs: Self, rhs: Float) -> Self {
    let left = lhs
            
    var result: Self = []
    for d in 0..<lhs.count {
      let new2d: Element = left[d].map { $0 + rhs }
      result.append(new2d)
    }
    
    return result
  }
  
  static func +(lhs: Float, rhs: Self) -> Self {
    var result: Self = []
    for d in 0..<rhs.count {
      let new2d: Element = rhs[d].map { $0 + lhs }
      result.append(new2d)
    }
    
    return result
  }
  
  
  static func -(lhs: Self, rhs: Float) -> Self {
    let left = lhs
            
    var result: Self = []
    for d in 0..<lhs.count {
      let new2d: Element = left[d].map { $0 - rhs }
      result.append(new2d)
    }
    
    return result
  }
  
  static func *(lhs: Self, rhs: Self) -> Self {
    let left = lhs
    let right = rhs
    
    let leftShape = left.shape
    let rightShape = right.shape
    
    precondition(leftShape == rightShape)
    
    let depth = leftShape[safe: 2] ?? 0
    let rows = leftShape[safe: 1] ?? 0
    
    var result: Self = []
    for d in 0..<depth {
      var new2d: Element = []
      for r in 0..<rows {
        new2d.append(left[d][r] * right[d][r])
      }
      result.append(new2d)
    }
    
    return result
  }
  
  static func /(lhs: Self, rhs: Self) -> Self {
    let left = lhs
    let right = rhs
    
    let leftShape = left.shape
    let rightShape = right.shape
    
    precondition(leftShape == rightShape)
    
    let depth = leftShape[safe: 2] ?? 0
    let rows = leftShape[safe: 1] ?? 0
    
    var result: Self = []
    for d in 0..<depth {
      var new2d: Element = []
      for r in 0..<rows {
        new2d.append(left[d][r] / right[d][r])
      }
      result.append(new2d)
    }
    
    return result
  }
  
  static func -(lhs: Self, rhs: Self) -> Self {
    let left = lhs
    let right = rhs
    
    let leftShape = left.shape
    let rightShape = right.shape
    
    precondition(leftShape == rightShape)
    
    let depth = leftShape[safe: 2] ?? 0
    let rows = leftShape[safe: 1] ?? 0
    
    var result: Self = []
    for d in 0..<depth {
      var new2d: Element = []
      for r in 0..<rows {
        new2d.append(left[d][r] - right[d][r])
      }
      result.append(new2d)
    }
    
    return result
  }
  
  static func +(lhs: Self, rhs: Self) -> Self {
    let left = lhs
    let right = rhs
    
    let leftShape = left.shape
    let rightShape = right.shape
    
    precondition(leftShape == rightShape)
    
    let depth = leftShape[safe: 2] ?? 0
    let rows = leftShape[safe: 1] ?? 0
    
    var result: Self = []
    for d in 0..<depth {
      var new2d: Element = []
      for r in 0..<rows {
        new2d.append(left[d][r] + right[d][r])
      }
      result.append(new2d)
    }
    return result
  }
}


public extension Array {
  func as3D() -> [[[Element]]] {
    let amount = count
    let result: [[[Element]]] = [[[Element]]].init(repeating: [[Element]].init(repeating: self,
                                                                               count: amount),
                                                   count: amount)
    return result
  }
  
  func as2D() -> [[Element]] {
    let amount = count
    let result: [[Element]] = [[Element]].init(repeating: self, count: amount)
    return result
  }
  
  subscript(safe safeIndex: Int, default: Element) -> Element {
    if safeIndex < 0 {
      return `default`
    }
    
    return self[safe: safeIndex] ?? `default`
  }
  
  subscript(_ multiple: [Int], default: Element) -> Self {
    var result: Self = []
    result.reserveCapacity(multiple.count)
    
    multiple.forEach { i in
      result.append(self[safe: i, `default`])
    }
    
    return result
  }
  
  subscript(range multiple: Range<Int>, default: Element) -> Self {
    var result: Self = []
    result.reserveCapacity(multiple.count)
    
    multiple.forEach { i in
      result.append(self[safe: i, `default`])
    }
    
    return result
  }

  subscript(range multiple: Range<Int>, dialate: Int, default: Element) -> Self {
    var result: Self = []
    result.reserveCapacity(multiple.count)
    
    var i: Int = 0
    var dialateTotal: Int = 0
    
    let range = [Int](multiple)

    while i < multiple.count {
      if i > 0 && dialateTotal < dialate {
        result.append(self[safe: -1, `default`])
        dialateTotal += 1
      } else {
        result.append(self[safe: range[i], `default`])
        i += 1
        dialateTotal = 0
      }
    }

    return result
  }
  
  subscript(range multiple: Range<Int>, padding: Int, dialate: Int, default: Element) -> Self {
    var result: Self = []
    //result.reserveCapacity(multiple.count)
    
    var i: Int = 0
    var dialateTotal: Int = 0
    var paddingTotal: Int = 0
    
    let range = [Int](multiple)
    
    while i < (multiple.count + padding * 4) {
      if (i > multiple.count || i == 0) && paddingTotal < padding {
        result.append(self[safe: -1, `default`])
        paddingTotal += 1
      } else if i > 0 && i < multiple.count && dialateTotal < dialate {
        result.append(self[safe: -1, `default`])
        dialateTotal += 1
      } else {
        if i < multiple.count {
          result.append(self[safe: range[i], `default`])
          paddingTotal = 0
          dialateTotal = 0
        }
        i += 1
      }
    }

    return result
  }
}

public extension Array where Element == [Float] {
  
  subscript(_ start: (row: Int, column: Int),
            end: (row: Int, column: Int),
            default: Float) -> Self {
    var result: Self = []
    
    let defaultRow = [Float].init(repeating: `default`, count: count)
    result.append(contentsOf: self[range: start.row..<end.row, defaultRow])
    
    return result.map { $0[range: start.column..<end.column, `default`] }
  }

  subscript(flat start: (row: Int, column: Int),
            end: (row: Int, column: Int),
            default: Float) -> [Float] {
    var result: [Float] = []
    
    let defaultRow = [Float].init(repeating: `default`, count: count)
    
    self[range: start.row..<end.row, defaultRow].forEach { row in
      let column = row[range: start.column..<end.column, `default`]
      result.append(contentsOf: column)
    }
        
    return result
  }

  subscript(_ start: (row: Int, column: Int),
            end: (row: Int, column: Int),
            dialate: Int,
            default: Float) -> Self {
    
    var result: Self = []

    let defaultRow = [Float].init(repeating: `default`, count: count)
    result.append(contentsOf: self[range: start.row..<end.row, dialate, defaultRow])
    
    return result.map { $0[range: start.column..<end.column, dialate, `default`] }
  }
  
  subscript(_ start: (row: Int, column: Int),
            end: (row: Int, column: Int),
            padding: Int,
            dialate: Int,
            default: Float) -> Self {
    
    var result: Self = []

    let defaultRow = [Float].init(repeating: `default`, count: count)
    result.append(contentsOf: self[range: start.row..<end.row, padding, dialate, defaultRow])
    
    return result.map { $0[range: start.column..<end.column, padding, dialate, `default`] }
  }
  
  subscript(flat start: (row: Int, column: Int),
            end: (row: Int, column: Int),
            dialate: Int,
            default: Float) -> [Float] {
    
    var result: [Float] = []

    let defaultRow = [Float].init(repeating: `default`, count: count)
    
    self[range: start.row..<end.row, dialate, defaultRow].forEach { row in
      let column = row[range: start.column..<end.column, dialate, `default`]
      result.append(contentsOf: column)
    }
            
    return result
  }
  
  subscript(flat start: (row: Int, column: Int),
            end: (row: Int, column: Int),
            padding: Int,
            dialate: Int,
            default: Float) -> [Float] {
    
    var result: [Float] = []

    let defaultRow = [Float].init(repeating: `default`, count: count)
    
    self[range: start.row..<end.row, padding, dialate, defaultRow].forEach { row in
      let column = row[range: start.column..<end.column, padding, dialate, `default`]
      result.append(contentsOf: column)
    }
            
    return result
  }
}


public extension Array where Element == [Float] {
  var sumOfSquares: Float {
    var result: Float = 0
    self.forEach { a in
      let stride = vDSP_Stride(1)
      let n = vDSP_Length(a.count)
      
      var c: Float = .nan
      
      vDSP_svesq(a,
                 stride,
                 &c,
                 n)
      
      result += c
    }

    return result
  }
  
  var mean: Float {
    var r: Float = 0
    var total = 0
    self.forEach { a in
      r += a.mean
      total += 1
    }
    
    return r / Float(total)
  }
  
  var sum: Float {
    var r: Float = 0
    self.forEach { a in
      r += a.sum
    }
    
    return r
  }
  
  static func *(lhs: Self, rhs: Float) -> Self {
    let left = lhs
            
    var result: Self = []
    for d in 0..<lhs.count {
      let new2d: Element = left[d] * rhs
      result.append(new2d)
    }
    
    return result
  }
  
  static func *(lhs: Float, rhs: Self) -> Self {
    var result: Self = []
    for d in 0..<rhs.count {
      let new2d: Element = rhs[d] * lhs
      result.append(new2d)
    }
    
    return result
  }
  
  static func /(lhs: Self, rhs: Float) -> Self {
    let left = lhs
            
    var result: Self = []
    for d in 0..<lhs.count {
      let new2d: Element = left[d] / rhs
      result.append(new2d)
    }
    
    return result
  }
  
  static func +(lhs: Self, rhs: Float) -> Self {
    let left = lhs
            
    var result: Self = []
    for d in 0..<lhs.count {
      let new2d: Element = left[d] + rhs
      result.append(new2d)
    }
    
    return result
  }
  
  static func +(lhs: Float, rhs: Self) -> Self {
    var result: Self = []
    for d in 0..<rhs.count {
      let new2d: Element = rhs[d] + lhs
      result.append(new2d)
    }
    
    return result
  }
  
  
  static func -(lhs: Self, rhs: Float) -> Self {
    let left = lhs
            
    var result: Self = []
    for d in 0..<lhs.count {
      let new2d: Element = left[d] - rhs
      result.append(new2d)
    }
    
    return result
  }
  
  static func *(lhs: Self, rhs: Self) -> Self {
    let left = lhs
    let right = rhs
    
    let leftShape = left.shape
    let rightShape = right.shape
    
    precondition(leftShape == rightShape)
    
    let depth = left.count
    
    var result: Self = []
    for d in 0..<depth {
      result.append(left[d] * right[d])
    }
    
    return result
  }
  
  static func /(lhs: Self, rhs: Self) -> Self {
    let left = lhs
    let right = rhs
    
    let leftShape = left.shape
    let rightShape = right.shape
    
    precondition(leftShape == rightShape)
    
    let depth = left.count
    
    var result: Self = []
    for d in 0..<depth {
      result.append(left[d] / right[d])
    }
    
    return result
  }
  
  static func -(lhs: Self, rhs: Self) -> Self {
    let left = lhs
    let right = rhs
    
    let leftShape = left.shape
    let rightShape = right.shape
    
    precondition(leftShape == rightShape)
    
    let depth = left.count
    
    var result: Self = []
    for d in 0..<depth {
      result.append(left[d] - right[d])
    }
    
    return result
  }
  
  static func +(lhs: Self, rhs: Self) -> Self {
    let left = lhs
    let right = rhs
    
    let leftShape = left.shape
    let rightShape = right.shape
    
    precondition(leftShape == rightShape)
    
    let depth = left.count
    
    var result: Self = []
    for d in 0..<depth {
      result.append(left[d] + right[d])
    }
    
    return result
  }
}
