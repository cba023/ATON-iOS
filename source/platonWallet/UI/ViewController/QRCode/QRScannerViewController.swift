//
//  QRScannerViewController.swift
//  platonWallet
//
//  Created by matrixelement on 26/10/2018.
//  Copyright © 2018 ju. All rights reserved.
//

import UIKit
import AVFoundation
import Localize_Swift
import ZXingObjC
import platonWeb3

private let scanFrameSize: CGFloat = 257.0

class QRScannerViewController: BaseViewController, AVCaptureMetadataOutputObjectsDelegate {

    fileprivate var capture: ZXCapture?
    fileprivate var isFirstApplyOrientation: Bool?
    fileprivate var captureSizeTransform: CGAffineTransform?

    lazy var captureSession: AVCaptureSession! = {

        let session = AVCaptureSession()

        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return nil}
        let videoInput: AVCaptureDeviceInput

        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return nil
        }

        if (session.canAddInput(videoInput)) {
            session.addInput(videoInput)
        } else {
            failed()
            return nil
        }

        let metadataOutput = AVCaptureMetadataOutput()

        if (session.canAddOutput(metadataOutput)) {
            session.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            failed()
            return nil
        }

        return session

    }()

    lazy var previewLayer: AVCaptureVideoPreviewLayer! = {

        let layer = AVCaptureVideoPreviewLayer(session: captureSession)
        layer.frame = view.bounds
        layer.backgroundColor = UIColor(rgb: 0x1B2137, alpha: 0.5).cgColor
        layer.videoGravity = .resizeAspectFill
        return layer

    }()

    var scanCompletion: ((String) -> Void)?

    lazy var scanLine: CALayer = {

        let layer = CALayer()
        layer.contents = UIImage(named: "qrcode_scan_line")?.cgImage
        layer.isHidden = true
        return layer

    }()

    convenience init(scanCompletion:@escaping (_ result: String) -> Void) {

        self.init()
        self.scanCompletion = scanCompletion

    }

    override func viewDidLoad() {
        super.viewDidLoad()
//        checkCamareAuthStatus()
//        setupUI()

        setupUITest()
    }

//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//
//        navigationController?.setNavigationBarHidden(false, animated: false)
//
//        startScanLineAnimation()
//        if (captureSession?.isRunning == false) {
//            captureSession.startRunning()
//        }
//    }

//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//
//        navigationController?.setNavigationBarHidden(true, animated: false)
//        stopScanLineAnimation()
//        if (captureSession?.isRunning == true) {
//            captureSession.stopRunning()
//        }
//    }

    public func rescan() {
        startScanLineAnimation()
        if (captureSession?.isRunning == false) {
            captureSession.startRunning()
        }
    }

    func setupUI() {
        //super.leftNavigationTitle = "QRScanerVC_nav_title"
        addScanLayer()
        perform(#selector(addTorchLayer), with: nil, afterDelay: 5.0)
        addAlbumButton()
    }

    func setupUITest() {
        capture = ZXCapture()
        guard let _capture = capture else { return }
        _capture.camera = _capture.back()
        _capture.focusMode =  .continuousAutoFocus
        _capture.delegate = self

        self.view.layer.addSublayer(_capture.layer)

    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if isFirstApplyOrientation == true { return }
        isFirstApplyOrientation = true
        applyOrientation()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: { (context) in
            // do nothing
        }) { [weak self] (context) in
            guard let weakSelf = self else { return }
            weakSelf.applyOrientation()
        }
    }

    func applyOrientation() {
        let orientation = UIApplication.shared.statusBarOrientation
        var captureRotation: Double
        var scanRectRotation: Double

        switch orientation {
        case .portrait:
            captureRotation = 0
            scanRectRotation = 90
            break

        case .landscapeLeft:
            captureRotation = 90
            scanRectRotation = 180
            break

        case .landscapeRight:
            captureRotation = 270
            scanRectRotation = 0
            break

        case .portraitUpsideDown:
            captureRotation = 180
            scanRectRotation = 270
            break

        default:
            captureRotation = 0
            scanRectRotation = 90
            break
        }

        applyRectOfInterest(orientation: orientation)

        let angleRadius = captureRotation / 180.0 * Double.pi
        let captureTranform = CGAffineTransform(rotationAngle: CGFloat(angleRadius))

        capture?.transform = captureTranform
        capture?.rotation = CGFloat(scanRectRotation)
        capture?.layer.frame = view.frame
    }

    func applyRectOfInterest(orientation: UIInterfaceOrientation) {
        var transformedVideoRect = self.view.frame
        guard
            let cameraSessionPreset = capture?.sessionPreset
            else { return }

        var scaleVideoX, scaleVideoY: CGFloat
        var videoHeight, videoWidth: CGFloat

        // Currently support only for 1920x1080 || 1280x720
        if cameraSessionPreset == AVCaptureSession.Preset.hd1920x1080.rawValue {
            videoHeight = 1080.0
            videoWidth = 1920.0
        } else {
            videoHeight = 720.0
            videoWidth = 1280.0
        }

        if orientation == UIInterfaceOrientation.portrait {
            scaleVideoX = self.view.frame.width / videoHeight
            scaleVideoY = self.view.frame.height / videoWidth

            // Convert CGPoint under portrait mode to map with orientation of image
            // because the image will be cropped before rotate
            // reference: https://github.com/TheLevelUp/ZXingObjC/issues/222
            let realX = transformedVideoRect.origin.y;
            let realY = self.view.frame.size.width - transformedVideoRect.size.width - transformedVideoRect.origin.x;
            let realWidth = transformedVideoRect.size.height;
            let realHeight = transformedVideoRect.size.width;
            transformedVideoRect = CGRect(x: realX, y: realY, width: realWidth, height: realHeight);

        } else {
            scaleVideoX = self.view.frame.width / videoWidth
            scaleVideoY = self.view.frame.height / videoHeight
        }

        captureSizeTransform = CGAffineTransform(scaleX: 1.0/scaleVideoX, y: 1.0/scaleVideoY)
        guard let _captureSizeTransform = captureSizeTransform else { return }
        let transformRect = transformedVideoRect.applying(_captureSizeTransform)
        capture?.scanRect = transformRect
    }

    func barcodeFormatToString(format: ZXBarcodeFormat) -> String {
        switch (format) {
        case kBarcodeFormatAztec:
            return "Aztec"

        case kBarcodeFormatCodabar:
            return "CODABAR"

        case kBarcodeFormatCode39:
            return "Code 39"

        case kBarcodeFormatCode93:
            return "Code 93"

        case kBarcodeFormatCode128:
            return "Code 128"

        case kBarcodeFormatDataMatrix:
            return "Data Matrix"

        case kBarcodeFormatEan8:
            return "EAN-8"

        case kBarcodeFormatEan13:
            return "EAN-13"

        case kBarcodeFormatITF:
            return "ITF"

        case kBarcodeFormatPDF417:
            return "PDF417"

        case kBarcodeFormatQRCode:
            return "QR Code"

        case kBarcodeFormatRSS14:
            return "RSS 14"

        case kBarcodeFormatRSSExpanded:
            return "RSS Expanded"

        case kBarcodeFormatUPCA:
            return "UPCA"

        case kBarcodeFormatUPCE:
            return "UPCE"

        case kBarcodeFormatUPCEANExtension:
            return "UPC/EAN extension"

        default:
            return "Unknown"
        }
    }

    private func addAlbumButton() {
        let buttonItem = UIBarButtonItem(title: Localized("scanviewcontroller_nav_right_item"), style: .plain, target: self, action: #selector(openAlbum))
        buttonItem.tintColor = .white
        self.navigationItem.rightBarButtonItem = buttonItem
    }

    func addScanLayer() {

        let layer = CALayer()
        layer.frame = view.bounds
        layer.backgroundColor = UIColor(rgb: 0x1B2137, alpha: 0.5).cgColor
        view.layer.addSublayer(layer)

        let path = UIBezierPath(rect: view.bounds)
        let x = (view.bounds.size.width - scanFrameSize) / 2
        let centerRect = CGRect(x: x, y: 137, width: scanFrameSize, height: scanFrameSize)

        path.append(UIBezierPath(rect: centerRect).reversing())
        let shape = CAShapeLayer()
        shape.path = path.cgPath
        layer.mask = shape

        let centerLayer = CALayer()
        centerLayer.frame = centerRect
        centerLayer.contents = UIImage(named: "qrCode_scan_frame")?.cgImage
        scanLine.frame = CGRect(x: 0, y: 0, width: centerLayer.frame.size.width, height: 3)
        centerLayer.addSublayer(scanLine)

        let labelFrame = CGRect(x: 0, y: centerLayer.frame.maxY + 16, width: kUIScreenWidth, height: 20)

        let label = UILabel(frame: labelFrame)
        label.textColor = UIColor(hex: "b6bbd0")
        label.font = UIFont.systemFont(ofSize: 14)
        label.localizedText = "scanviewcontroller_scan"
        label.textAlignment = .center
        view.addSubview(label)
        //view.layer.addSublayer(label.layer)

        view.layer.addSublayer(centerLayer)

    }

    @objc private func addTorchLayer() {
        let torchButton = UIButton(frame: CGRect(x: (self.view.frame.width - 24)/2.0, y: 137 + scanFrameSize - 24 - 26, width: 24, height: 24))
        torchButton.setImage(UIImage(named: "icon_flashlight_off"), for: .normal)
        torchButton.setImage(UIImage(named: "icon_flashlight_on"), for: .selected)
        torchButton.addTarget(self, action: #selector(openTorch(_:)), for: .touchUpInside)
        view.addSubview(torchButton)

        let torchLabel = UILabel(frame: CGRect(x: (view.bounds.size.width - scanFrameSize) / 2, y: torchButton.frame.maxY + 4, width: scanFrameSize, height: 16))
        torchLabel.textColor = UIColor(hex: "b6bbd0")
        torchLabel.font = UIFont.systemFont(ofSize: 14)
        torchLabel.localizedText = "scanviewcontroller_torch"
        torchLabel.textAlignment = .center
        view.addSubview(torchLabel)
    }

    override func rt_customBackItem(withTarget target: Any!, action: Selector!) -> UIBarButtonItem! {
        let barButtonItem = UIBarButtonItem(image: UIImage(named: "nav_back"), style: .plain, target: self, action: #selector(onNavigationBack))
        barButtonItem.tintColor = .white
        return barButtonItem
    }

    func checkCamareAuthStatus() {

        func showAlert() {

            let alert = PAlertController(title: Localized("alert_cameraUsageDeny_title"), message: Localized("alert_cameraUsageDeny_msg"))
            alert.addAction(title: Localized("alert_cancelBtn_title")) {
                self.navigationController?.popViewController(animated: true)
            }

            alert.addAction(title: Localized("alert_cameraUsageDeny_gotoSettings_title")) {

                UIApplication.shared.openURL(URL(string: UIApplication.openSettingsURLString)!)

            }

            alert.show(inViewController: self)
        }

        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {

        case .authorized:

            view.layer.insertSublayer(self.previewLayer, at: 0)

        case .denied:

            showAlert()

        case .notDetermined:

            AVCaptureDevice.requestAccess(for: .video) { (granted) in

                DispatchQueue.main.async {
                    if granted {
                        self.view.layer.insertSublayer(self.previewLayer, at: 0)
                    } else {
                        showAlert()
                    }
                }

            }

        default:
            break
        }

    }

    func startScanLineAnimation() {

        let animate = CABasicAnimation(keyPath: "position.y")
        animate.duration = 2
        animate.repeatCount = MAXFLOAT
        animate.toValue = scanFrameSize
        scanLine.add(animate, forKey: nil)
        scanLine.isHidden = false
    }

    func stopScanLineAnimation() {

        scanLine.removeAllAnimations()
        scanLine.isHidden = true

    }

    @objc func onNavigationBack() {
        navigationController?.popViewController(animated: true)
    }

    func failed() {
        let ac = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
        captureSession = nil
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {

        captureSession.stopRunning()

        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else {

                if (captureSession?.isRunning == false) {
                    captureSession.startRunning()
                }
                return

            }
            scanCompletion?(stringValue)
            //AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
//            found(code: stringValue)

        }

    }

    override var prefersStatusBarHidden: Bool {
        return false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}

extension QRScannerViewController {
    @objc private func openTorch(_ sender: UIButton) {
        guard let device = AVCaptureDevice.default(for: AVMediaType.video) else {
            print("无法获取到手电筒设备")
            return
        }
        if device.hasTorch && device.isTorchAvailable {
            try? device.lockForConfiguration()

            device.torchMode = device.torchMode == .off ? .on : .off
            sender.isSelected = (device.torchMode == .on)
            device.unlockForConfiguration()
        }
    }

    @objc private func openAlbum() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }
}

extension QRScannerViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {

        showLoadingHUD(text: Localized("scanviewcontroller_scan_loading"), animated: true)

        let image = info[.originalImage] as! UIImage

        //对于截图，尝试各种尺寸的拉伸，否则识别不出来
        let sizeArray = [CGSize(width: 1242, height: 2688),
                         CGSize(width: 828, height: 1792),
                         CGSize(width: 1125, height: 2436),
                         CGSize(width: 1242, height: 2208),
                         CGSize(width: 750, height: 1334),
                         CGSize(width: 640, height: 1136)]
        var featureQR: CIQRCodeFeature?
        for item in sizeArray {
            let newImage = image.resizeImage(image: image, newSize: CGSize(width: item.width, height: item.height))
            let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
            let featureArr = detector?.features(in: CIImage(cgImage: newImage.cgImage!))

            if let feature = featureArr?.first as? CIQRCodeFeature {
                featureQR = feature
                break
            }
        }

        if let feature = featureQR {
            let message = feature.messageString!

            self.dismiss(animated: true) { [weak self] in
                guard let self = self else { return }
                self.hideLoadingHUD()
                self.scanCompletion?(message)
            }
        } else {
            self.hideLoadingHUD()
            self.showMessage(text: Localized("scanviewcontroller_scan_result_notfound"), delay: 1.5)
            self.dismiss(animated: true, completion: nil)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension QRScannerViewController: ZXCaptureDelegate {
    func captureResult(_ capture: ZXCapture!, result: ZXResult!) {
        let format = barcodeFormatToString(format: result.barcodeFormat)
        print(result.text)
        print(result.rawBytes)

        let dict = result!.resultMetadata![kResultMetadataTypeByteSegments.rawValue] as? [Any]

//        if (saResult.resultMetadata[@(kResultMetadataTypeByteSegments)]) {
//            for (ZXByteArray *segment in saResult.resultMetadata[@(kResultMetadataTypeByteSegments)]) {
//                memcpy(newByteSegment.array, segment.array, segment.length * sizeof(int8_t));
//                byteSegmentIndex += segment.length;
//            }
//        }
//        let uui = dict.allValues.last
        let bytes = dict?.first as! ZXByteArray
        print(dict)
        let data = Data(buffer: UnsafeBufferPointer(start: bytes.array, count: Int(bytes.length)))

        let isostring = String(data: data, encoding: .isoLatin1)?.cString(using: .isoLatin1)
        let result = String(data: data, encoding: .isoLatin1)
        String(data: data, encoding: .)
        isostring?.withUnsafeBufferPointer({ ptr in
            let s = String(cString: ptr.baseAddress!)
            print(s)
        })
//        let isostring = String(cString: result.rawBytes.array, encoding: .isoLatin1)!
        print(isostring)
//        let isoData = isostring!.data(using: .isoLatin1)!
//        print(isoData.count)
        let ungzipData = try? data.gunzipped()
        print(ungzipData?.count)

        let utf8String = String(data: ungzipData!, encoding: .utf8)
        print(utf8String)
    }
}
