import SwiftUI
import AVFoundation
import PhotosUI

struct CameraView: View {
    @Binding var capturedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: PhotosPickerItem?
    @State private var showingImagePicker = false
    @State private var cameraController: CameraViewController?
    
    var body: some View {
        NavigationStack {
            ZStack {
                CameraPreview(capturedImage: $capturedImage) { controller in
                    cameraController = controller
                }
                .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    HStack(spacing: 40) {
                        // Photo Library Button
                        PhotosPicker(selection: $selectedItem,
                                   matching: .images,
                                   photoLibrary: .shared()) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .onChange(of: selectedItem) { oldItem, newItem in
                            print("📷 [CameraView] selectedItem onChange triggered")
                            print("   Old item: \(oldItem != nil ? "exists" : "nil")")
                            print("   New item: \(newItem != nil ? "exists" : "nil")")
                            
                            Task {
                                print("📸 [CameraView] Photo selected from library")
                                print("   Starting data loading...")
                                
                                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                    print("   Data loaded, size: \(data.count) bytes")
                                    
                                    if let image = UIImage(data: data) {
                                        print("✅ [CameraView] Image created successfully")
                                        print("   Image size: \(image.size)")
                                        print("   Setting capturedImage...")
                                        capturedImage = image
                                        print("   Dismissing view...")
                                        dismiss()
                                        print("✅ [CameraView] Library photo processing complete")
                                    } else {
                                        print("❌ [CameraView] Failed to create UIImage from data")
                                    }
                                } else {
                                    print("❌ [CameraView] Failed to load data from PhotosPicker")
                                }
                            }
                        }
                        
                        // Capture Button
                        Button(action: {
                            print("📸 [CameraView] Capture button pressed")
                            cameraController?.capturePhoto()
                        }) {
                            Circle()
                                .stroke(Color.white, lineWidth: 5)
                                .frame(width: 70, height: 70)
                                .overlay(
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 60, height: 60)
                                )
                        }
                        
                        // Placeholder for balance
                        Color.clear
                            .frame(width: 50, height: 50)
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        print("📸 [CameraView] Cancel button pressed")
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .onAppear {
            print("📸 [CameraView] View appeared")
        }
        .onDisappear {
            print("📸 [CameraView] View disappeared")
        }
    }
}

struct CameraPreview: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    let onControllerCreated: (CameraViewController) -> Void
    
    func makeUIViewController(context: Context) -> CameraViewController {
        print("📸 [CameraPreview] Creating CameraViewController")
        let controller = CameraViewController()
        controller.capturedImage = $capturedImage
        onControllerCreated(controller)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}

class CameraViewController: UIViewController {
    var capturedImage: Binding<UIImage?>?
    private var captureSession: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var photoOutput: AVCapturePhotoOutput?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("📸 [CameraViewController] viewDidLoad")
        
        // Check camera permissions
        AVCaptureDevice.requestAccess(for: .video) { granted in
            print("📸 [CameraViewController] Camera permission granted: \(granted)")
            if granted {
                DispatchQueue.main.async {
                    self.setupCamera()
                }
            } else {
                print("❌ [CameraViewController] Camera permission denied")
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
    
    private func setupCamera() {
        print("📸 [CameraViewController] Setting up camera")
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .photo
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            print("❌ [CameraViewController] No camera device found")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            
            guard let captureSession = captureSession else {
                print("❌ [CameraViewController] Capture session is nil")
                return
            }
            
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                print("✅ [CameraViewController] Camera input added")
            } else {
                print("❌ [CameraViewController] Cannot add camera input")
                return
            }
            
            photoOutput = AVCapturePhotoOutput()
            if let photoOutput = photoOutput {
                if captureSession.canAddOutput(photoOutput) {
                    captureSession.addOutput(photoOutput)
                    print("✅ [CameraViewController] Photo output added")
                } else {
                    print("❌ [CameraViewController] Cannot add photo output")
                    return
                }
            }
            
            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer?.videoGravity = .resizeAspectFill
            
            if let previewLayer = previewLayer {
                view.layer.addSublayer(previewLayer)
                print("✅ [CameraViewController] Preview layer added")
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                captureSession.startRunning()
                print("✅ [CameraViewController] Camera session started")
            }
        } catch {
            print("❌ [CameraViewController] Error setting up camera: \(error)")
        }
    }
    
    func capturePhoto() {
        print("📸 [CameraViewController] capturePhoto() called")
        
        guard let photoOutput = photoOutput else {
            print("❌ [CameraViewController] Photo output is nil")
            return
        }
        
        guard let captureSession = captureSession, captureSession.isRunning else {
            print("❌ [CameraViewController] Capture session is not running")
            return
        }
        
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto
        
        print("📸 [CameraViewController] Capturing photo with settings")
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        print("📸 [CameraViewController] Photo processing finished")
        
        if let error = error {
            print("❌ [CameraViewController] Photo capture error: \(error)")
            return
        }
        
        guard let imageData = photo.fileDataRepresentation() else {
            print("❌ [CameraViewController] Failed to get image data")
            return
        }
        
        guard let image = UIImage(data: imageData) else {
            print("❌ [CameraViewController] Failed to create UIImage")
            return
        }
        
        print("✅ [CameraViewController] Photo captured successfully")
        
        DispatchQueue.main.async {
            print("📸 [CameraViewController] Setting captured image...")
            print("   Image size: \(image.size)")
            print("   Current capturedImage binding: \(self.capturedImage != nil ? "exists" : "nil")")
            
            self.capturedImage?.wrappedValue = image
            print("   Image set to binding")
            
            // Find the presenting view controller and dismiss
            print("📸 [CameraViewController] Finding view controller hierarchy...")
            var currentVC: UIViewController? = self
            while let vc = currentVC?.parent {
                currentVC = vc
            }
            print("   Root VC: \(type(of: currentVC))")
            
            if let presentedVC = currentVC?.presentedViewController {
                print("📸 [CameraViewController] Found presented VC, dismissing...")
                presentedVC.dismiss(animated: true) {
                    print("✅ [CameraViewController] Dismiss completed")
                }
            } else if let navigationController = currentVC?.navigationController {
                print("📸 [CameraViewController] Found nav controller, popping...")
                navigationController.popViewController(animated: true)
            } else {
                print("⚠️ [CameraViewController] No suitable dismiss method found")
            }
        }
    }
}

#Preview {
    CameraView(capturedImage: .constant(nil))
}