//
//  Canvas.swift
//  MUGE
//
//  Created by Kota on 12/3/25.
//
@preconcurrency import typealias Combine.PassthroughSubject
@preconcurrency import SwiftUI
@preconcurrency import os.log
import simd
@usableFromInline
struct Canvas {
    @usableFromInline let artwork: Artwork
    @usableFromInline
    func makeCoordinator() -> Coordinator {
        try!.init(artwork: artwork)
    }
}
#if canImport(UIKit)
//@usableFromInline
//final class MTLViewController: UIViewController {
//    @usableFromInline var link: Optional<CAMetalDisplayLink> = .none
//    @usableFromInline var draw: Optional<(@Sendable (CFTimeInterval, CAMetalDrawable) -> Void)> = .none
//    @inlinable
//    override func loadView() {
//        view = MTLView()
//        link = (view.layer as?CAMetalLayer).map(CAMetalDisplayLink.init(metalLayer:))
//        link?.delegate = self // weak ref
//    }
//    @inlinable
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        link?.add(to: .main, forMode: .default)
//    }
//    @inlinable
//    override func viewWillDisappear(_ animated: Bool) {
//        link?.remove(from: .main, forMode: .default)
//        super.viewWillDisappear(animated)
//    }
//}
//extension Canvas: UIViewControllerRepresentable {
//    @usableFromInline
//    func makeUIViewController(context: Context) -> MTLViewController {
//        let controller = MTLViewController()
//        do {
//            try controller.setup(with: artwork)
//        } catch {
//            os_log(.error, log: .default, "%{public}@", String(describing: error))
//        }
//        return controller
//    }
//    @inlinable
//    func updateUIViewController(_ nsViewController: MTLViewController, context: Context) {
//        
//    }
//}
#else
@usableFromInline
final class MTLViewController: NSViewController {
    @usableFromInline var link: CAMetalDisplayLink?
    @usableFromInline var pass: PassthroughSubject<(SIMD2<Float64>, SwiftUI.Gesture), Never>?
    @inlinable
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addGestureRecognizer(NSClickGestureRecognizer(target: self, action: #selector(recognise(gesture:))))
        view.addGestureRecognizer(NSPressGestureRecognizer(target: self, action: #selector(recognise(gesture:))))
        view.addGestureRecognizer(NSRotationGestureRecognizer(target: self, action: #selector(recognise(gesture:))))
        view.addGestureRecognizer(NSMagnificationGestureRecognizer(target: self, action: #selector(recognise(gesture:))))
    }
    @inlinable
    override func viewDidAppear() {
        super.viewDidAppear()
        link?.add(to: .main, forMode: .default)
    }
    @inlinable
    override func viewWillDisappear() {
        link?.remove(from: .main, forMode: .default)
        super.viewWillDisappear()
    }
    @inlinable
    @objc
    func recognise(gesture: NSGestureRecognizer) {
        switch gesture.view {
        case.some(view):
            assert(MemoryLayout<Float64>.stride == MemoryLayout<CGFloat>.stride)
            let point = unsafeBitCast(gesture.location(in: view), to: SIMD2<Float64>.self) / unsafeBitCast(view.bounds.size, to: SIMD2<Float64>.self)
            switch gesture {
            case let tap as NSClickGestureRecognizer:
                pass?.send((point, TapGesture(count: tap.numberOfClicksRequired)))
            case let press as NSPressGestureRecognizer:
                pass?.send((point, LongPressGesture(minimumDuration: press.minimumPressDuration)))
            case let rot as NSRotationGestureRecognizer:
                pass?.send((point, RotateGesture(minimumAngleDelta: .init(degrees: rot.rotationInDegrees))))
            case let mag as NSMagnificationGestureRecognizer:
                pass?.send((point, MagnifyGesture(minimumScaleDelta: mag.magnification)))
            default:
                break
            }
        case.some,.none:
            break
        }
    }
}
extension Canvas: NSViewControllerRepresentable {
    @usableFromInline
    func makeNSViewController(context: Context) -> MTLViewController {
        let controller = MTLViewController()
        controller.view.layer = context.coordinator.screen
        controller.link = .some(context.coordinator.displaylink)
        controller.pass = .some(context.coordinator.signal)
        return controller
    }
    @inlinable
    func updateNSViewController(_ nsViewController: MTLViewController, context: Context) {
        
    }
    @inlinable
    func sizeThatFits(_ proposal: ProposedViewSize, nsViewController: MTLViewController, context: Context) -> CGSize? {
        guard case.some(let width) = proposal.width, 0 < width, case.some(let height) = proposal.height, 0 < height else {
            return.none
        }
        context.coordinator.screen.drawableSize = .init(width: width, height: height)
        return.some(context.coordinator.screen.drawableSize)
    }
}
#endif
public func Exhibit(artwork: Artwork) -> some SwiftUI.View {
    Canvas(artwork: artwork)
}
