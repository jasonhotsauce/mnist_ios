//
//  ViewController.swift
//  MNIST
//
//  Created by Wenbin Zhang on 9/24/18.
//  Copyright © 2018 Wenbin Zhang. All rights reserved.
//

import UIKit
import CoreML

class ViewController: UIViewController {
    
    let canvasView: CanvasView
    let predictLabel: UILabel
    let predictButton: UIButton
    let resetButton: UIButton
    let model: MnistCNN
    var pendingWorkItem: DispatchWorkItem?
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        canvasView = CanvasView()
        canvasView.backgroundColor = .black
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        predictLabel = UILabel(frame: .zero)
        predictLabel.backgroundColor = .white
        predictLabel.font = UIFont.boldSystemFont(ofSize: 25)
        predictLabel.textColor = .black
        predictLabel.textAlignment = .center
        predictLabel.translatesAutoresizingMaskIntoConstraints = false
        predictButton = UIButton(frame: .zero)
        predictButton.setTitle("Predict", for: .normal)
        predictButton.setTitleColor(.blue, for: .normal)
        predictButton.translatesAutoresizingMaskIntoConstraints = false
        resetButton = UIButton(frame: .zero)
        resetButton.setTitle("Clear", for: .normal)
        resetButton.setTitleColor(.red, for: .normal)
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        
        model = MnistCNN()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    override func loadView() {
        super.loadView()
        view.backgroundColor = .gray
        view.addSubview(canvasView)
        view.addSubview(predictLabel)
        view.addSubview(resetButton)
        view.addSubview(predictButton)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupConstraints()
        predictButton.addTarget(self, action: #selector(didTapPredict), for: .touchUpInside)
        resetButton.addTarget(self, action: #selector(didTapReset), for: .touchUpInside)
    }
    
    private func setupConstraints() {
        let views: [String : Any] = [
            "canvas": canvasView,
            "label": predictLabel,
            "predict": predictButton,
            "reset": resetButton,
        ]
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-[canvas]-|",
                                                           options: [],
                                                           metrics: nil,
                                                           views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-[predict]-[reset(==predict)]-|",
                                                           options: .alignAllFirstBaseline,
                                                           metrics: nil,
                                                           views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[canvas]-[label(200)]",
                                                           options: [.alignAllCenterX, .alignAllLeading, .alignAllTrailing],
                                                           metrics: nil,
                                                           views: views))
        predictLabel.setContentHuggingPriority(.required, for: .vertical)
        canvasView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5)
        view.addConstraint(NSLayoutConstraint(item: predictButton, attribute: .top, relatedBy: .equal, toItem: predictLabel, attribute: .bottom, multiplier: 1.0, constant: 10))
        view.safeAreaLayoutGuide.bottomAnchor.constraint(equalToSystemSpacingBelow: predictButton.bottomAnchor, multiplier: 1.0).isActive = true
    }
    
    @objc
    private func didTapPredict() {
        guard canvasView.hasContent else {
            return
        }
        predictLabel.text = nil
        pendingWorkItem?.cancel()
        guard let pixelBuff = layerContentToPixelBuffPipline(first: content(),
                                                             then: pixelBuff())(canvasView.layer,
                                                                                CGSize(width: 28, height: 28)) else {
                                                                                    return
        }
        let workItem = DispatchWorkItem { [weak self] in
            do {
                let output = try self?.model.prediction(image: pixelBuff)
                DispatchQueue.main.async {
                    self?.predictLabel.text = output?.classLabel
                }
            } catch {
                print("Error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.predictLabel.text = nil
                }
            }
        }
        pendingWorkItem = workItem
        DispatchQueue.global().async(execute: workItem)
    }
    
    @objc
    private func didTapReset() {
        pendingWorkItem?.cancel()
        predictLabel.text = nil
        canvasView.reset()
    }
}

