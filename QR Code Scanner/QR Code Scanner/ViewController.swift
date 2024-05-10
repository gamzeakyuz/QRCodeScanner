//
//  ViewController.swift
//  QR Code Scanner
//
//  Created by Gamze Akyüz on 23.03.2024.
//

import UIKit
import VisionKit
import Vision

class ViewController: UIViewController {
    
    var scannerAvailable: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func scanButton(_ sender: Any) {
        
        guard scannerAvailable == true else {
            return
        }
        
        let regonizedDataTypes:Set<DataScannerViewController.RecognizedDataType> = [
            
            .text(),
            .barcode()
        
        ]
        
        let dataScanner = DataScannerViewController(recognizedDataTypes: regonizedDataTypes, isHighlightingEnabled: true)
        dataScanner.delegate = self
        present(dataScanner, animated: true) {
            try? dataScanner.startScanning()
        }
        
    }
    
    @IBAction func scanQRFromGallery(_ sender: Any) {
           let imagePicker = UIImagePickerController()
           imagePicker.delegate = self
           imagePicker.sourceType = .photoLibrary
           imagePicker.allowsEditing = false
           present(imagePicker, animated: true, completion: nil)
       }
       
       func processImage(_ image: UIImage) {
           guard let cgImage = image.cgImage else { return }
           
           let request = VNRecognizeTextRequest { (request, error) in
               guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
               
               var detectedText = ""
               for observation in observations {
                   guard let topCandidate = observation.topCandidates(1).first else { continue }
                   detectedText += topCandidate.string + "\n"
               }
               
               print("Detected QR Code: \(detectedText)")
               // Burada QR kodu bulunduğunda yapılması gereken eylemi gerçekleştirebilirsiniz.
               if detectedText.starts(with: "http://") || detectedText.starts(with: "https://") {
                   if let url = URL(string: detectedText) {
                       UIApplication.shared.open(url)
                   }
               }
           }
           
           let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
           try? handler.perform([request])
       }

}

extension ViewController: DataScannerViewControllerDelegate {
    
    func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
        switch item {
        case .text(let text):
            print("text :\(text.transcript)")
            UIPasteboard.general.string = text.transcript
            dataScanner.stopScanning()
            dataScanner.dismiss(animated: true)
        case .barcode(let code):
            guard let urlString = code.payloadStringValue, let url = URL(string: urlString) else { return }
            UIApplication.shared.open(url)
            dataScanner.stopScanning()
            dataScanner.dismiss(animated: true)
        default:
            print("Unexpected item")
        }
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        if let image = info[.originalImage] as? UIImage {
            processImage(image)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}
