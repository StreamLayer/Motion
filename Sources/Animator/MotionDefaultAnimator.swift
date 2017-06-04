/*
 * The MIT License (MIT)
 *
 * Copyright (C) 2017, Daniel Dahan and CosmicMind, Inc. <http://cosmicmind.com>.
 * All rights reserved.
 *
 * Original Inspiration & Author
 * Copyright (c) 2016 Luke Zhao <me@lkzhao.com>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit

internal extension UIView {
  func optimizedDuration(fromPosition: CGPoint, toPosition: CGPoint?, size: CGSize?, transform: CATransform3D?) -> TimeInterval {
    let fromPos = fromPosition
    let toPos = toPosition ?? fromPos
    let fromSize = (layer.presentation() ?? layer).bounds.size
    let toSize = size ?? fromSize
    let fromTransform = (layer.presentation() ?? layer).transform
    let toTransform = transform ?? fromTransform

    let realFromPos = CGPoint.zero.transform(fromTransform) + fromPos
    let realToPos = CGPoint.zero.transform(toTransform) + toPos

    let realFromSize = fromSize.transform(fromTransform)
    let realToSize = toSize.transform(toTransform)

    let movePoints = (realFromPos.distance(realToPos) + realFromSize.point.distance(realToSize.point))

    // duration is 0.2 @ 0 to 0.375 @ 500
    let duration = 0.208 + Double(movePoints.clamp(0, 500)) / 3000
    return duration
  }
}

protocol HasInsertOrder: class {
  var insertToViewFirst: Bool { get set }
}
internal class MotionDefaultAnimator<ViewContext: MotionAnimatorViewContext>: MotionAnimator, HasInsertOrder {
  weak public var context: MotionContext!
  var viewContexts: [UIView: ViewContext] = [:]
  internal var insertToViewFirst = false

  public func seekTo(timePassed: TimeInterval) {
    for viewContext in viewContexts.values {
      viewContext.seek(timePassed: timePassed)
    }
  }

  public func resume(timePassed: TimeInterval, reverse: Bool) -> TimeInterval {
    var duration: TimeInterval = 0
    for (_, context) in viewContexts {
      context.resume(timePassed: timePassed, reverse: reverse)
      duration = max(duration, context.duration)
    }
    return duration
  }

  public func apply(state: MotionTargetState, to view: UIView) {
    if let context = viewContexts[view] {
      context.apply(state:state)
    }
  }

  public func canAnimate(view: UIView, appearing: Bool) -> Bool {
    guard let state = context[view] else { return false }
    return ViewContext.canAnimate(view: view, state: state, appearing: appearing)
  }

  public func animate(fromViews: [UIView], toViews: [UIView]) -> TimeInterval {
    var duration: TimeInterval = 0

    if insertToViewFirst {
      for v in toViews { animate(view: v, appearing: true) }
      for v in fromViews { animate(view: v, appearing: false) }
    } else {
      for v in fromViews { animate(view: v, appearing: false) }
      for v in toViews { animate(view: v, appearing: true) }
    }

    for viewContext in viewContexts.values {
      duration = max(duration, viewContext.duration)
    }

    return duration
  }

  func animate(view: UIView, appearing: Bool) {
    let snapshot = context.snapshotView(for: view)
    let viewContext = ViewContext(animator:self, snapshot: snapshot, targetState: context[view]!)
    viewContexts[view] = viewContext
    viewContext.startAnimations(appearing: appearing)
  }

  public func clean() {
    for vc in viewContexts.values {
      vc.clean()
    }
    viewContexts.removeAll()
    insertToViewFirst = false
  }
}
