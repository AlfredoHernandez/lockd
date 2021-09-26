//
//  PasswordView.swift
//  PasswordGenerator
//
//  Created by Iliane Zedadra on 06/05/2021.
//

import SwiftUI
import MobileCoreServices
import LocalAuthentication

struct PasswordGeneratorView: View {
    
    @ObservedObject var viewModel = PasswordGeneratorViewModel()
    @Environment(\.colorScheme) var colorScheme
    @State private var isUnlocked = false
    @State private var uppercased = true
    @State private var specialCharacters = true
    @State private var characterCount = 20.0
    @State private var withNumbers = true
    @State private var generatedPassword = ""
    @State private var savePasswordSheetIsPresented = false
    @ObservedObject var settings: SettingsViewModel
    @ObservedObject var passwordViewModel: PasswordListViewModel
    @State private var showAnimation = false
    @State private var characters = [String]()
    @State private var clipboardSaveAnimation = false
    @State private var currentPasswordEntropy = 0.0
    @State private var entropySheetIsPresented = false
    
    var body: some View {
        
        NavigationView {
            ZStack {
                Form {
                    
                    Section(header: Text("Mot de passe généré aléatoirement")) {
                        
                        HStack {
                            
                            Spacer()
                            
                            HStack(spacing: 0.5) {
                                ForEach(characters, id: \.self) { character in

                                    Text(character)
                                        .foregroundColor(viewModel.specialCharactersArray.contains(character) ? Color.init(hexadecimal: "#f16581") : viewModel.numbersArray.contains(character) ? Color.init(hexadecimal: "#4EB3BC") : viewModel.alphabet.contains(character) ? .gray : Color.init(hexadecimal: "#ffbc42"))
                                }
                            }                                .font(characterCount > 25 ? .system(size: 15) : .body)
                            .animation(.easeOut(duration: 0.1))
                            
                            Spacer()
                            
                            Button(action: {
                                settings.copyToClipboard(password: generatedPassword)
                                clipboardSaveAnimation = true
                                viewModel.copyPasswordHaptic()
                                
                            }, label: {
                                Image(systemName: "doc.on.doc")
                                    .foregroundColor(settings.colors[settings.accentColorIndex])
                                
                                
                            }).buttonStyle(PlainButtonStyle())
                        }
                        
                        HStack {
                            Spacer()
                            Button(action: { savePasswordSheetIsPresented.toggle()
                                
                            }, label: {
                                Text("Ajouter au coffre fort")
                                    .foregroundColor(settings.colors[settings.accentColorIndex])
                                
                                
                            }).buttonStyle(PlainButtonStyle())
                            Spacer()
                        }
                    }
                    
                    Section(header: Text("Nombre de caractères")) {
                        
                        HStack {
                            Slider(value: $characterCount, in: viewModel.passwordLenghtRange, step: 1)
                            Divider().frame(minWidth: 20)
                            
                            Button(action: { entropySheetIsPresented.toggle() }, label:  PasswordStrenghtView(entropy: currentPasswordEntropy, characterCount: characterCount)
                                    .frame(minWidth: 25))
                                .buttonStyle(PlainButtonStyle())
                           
                        }
                        .sheet(isPresented: $entropySheetIsPresented, content: { SecurityInfoView()})
                        
                        Button(action: {
                            
                            viewModel.generateButtonHaptic()
                            characters = viewModel.generatePassword(lenght: Int(characterCount), specialCharacters: specialCharacters, uppercase: uppercased, numbers: withNumbers)
                                generatedPassword = characters.joined()
                                currentPasswordEntropy = viewModel.calculatePasswordEntropy(password: characters.joined())
                                viewModel.adaptativeSliderHaptic(entropy: currentPasswordEntropy)
                            
                        },
                               label: {
                            HStack {
                                Spacer()
                                Label(
                                    title: { Text("Générer") },
                                    icon: { Image(systemName: "arrow.clockwise") })
                                Spacer()
                            }
                        })
                        .foregroundColor(settings.colors[settings.accentColorIndex])
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Section(header: Text("Inclure"), footer: Text("Note : chaque paramètre actif renforce la sécurité du mot de passe.").padding()) {
                        
                        Toggle(isOn: $specialCharacters, label: {
                            HStack {
                                Text("Caractères spéciaux")
                                Text("&-$").foregroundColor(Color.init(hexadecimal: "#f16581"))
                            }
                        })
                        .toggleStyle(SwitchToggleStyle(tint: settings.colors[settings.accentColorIndex]))
                        Toggle(isOn: $uppercased, label: {
                            HStack {
                                Text("Majuscules")
                                Text("A-Z").foregroundColor(Color.init(hexadecimal: "#ffbc42"))
                            }
                            
                        })
                        .toggleStyle(SwitchToggleStyle(tint: settings.colors[settings.accentColorIndex]))
                        Toggle(isOn: $withNumbers, label: {
                            HStack {
                                Text("Chiffres")
                                Text("0-9").foregroundColor(Color.init(hexadecimal: "#4EB3BC"))
                            }
                        })
                        .toggleStyle(SwitchToggleStyle(tint: settings.colors[settings.accentColorIndex]))
                    }
                    
                }.navigationBarTitle("Générateur")
            
                if passwordViewModel.showAnimation {
                    PopupAnimation(settings: settings, message: "Ajouté au coffre")
                        .onAppear(perform: { animationDisappear() })
                        .animation(.easeInOut(duration: 0.1))
                }
                
                if clipboardSaveAnimation {
                    PopupAnimation(settings: settings, message: settings.ephemeralClipboard ? "Copié! (60s)" : "Copié!")
                        .onAppear(perform: { clipBoardAnimationDisapear() })
                        .animation(.easeInOut(duration: 0.1))
                }
            }
            
        }.sheet(isPresented: $savePasswordSheetIsPresented ,  content: {
            SavePasswordView(password: $generatedPassword, sheetIsPresented: $savePasswordSheetIsPresented, generatedPasswordIsPresented: true, viewModel: passwordViewModel, settings: settings)
                .environment(\.colorScheme, colorScheme)
                .foregroundColor(settings.colors[settings.accentColorIndex])
        })
        .onChange(of: characterCount, perform: { _ in
            characters = viewModel.generatePassword(lenght: Int(characterCount), specialCharacters: specialCharacters, uppercase: uppercased, numbers: withNumbers)
            generatedPassword = characters.joined()
            currentPasswordEntropy = viewModel.calculatePasswordEntropy(password: characters.joined())
            viewModel.adaptativeSliderHaptic(entropy: currentPasswordEntropy)
        })
        .onChange(of: uppercased, perform: { _ in
            characters = viewModel.generatePassword(lenght: Int(characterCount), specialCharacters: specialCharacters, uppercase: uppercased, numbers: withNumbers)
            generatedPassword = characters.joined()
            currentPasswordEntropy = viewModel.calculatePasswordEntropy(password: characters.joined())
        })
        .onChange(of: specialCharacters, perform: { _ in
            characters = viewModel.generatePassword(lenght: Int(characterCount), specialCharacters: specialCharacters, uppercase: uppercased, numbers: withNumbers)
            generatedPassword = characters.joined()
            currentPasswordEntropy = viewModel.calculatePasswordEntropy(password: characters.joined())
        })
        .onChange(of: withNumbers, perform: { _ in
            characters = viewModel.generatePassword(lenght: Int(characterCount), specialCharacters: specialCharacters, uppercase: uppercased, numbers: withNumbers)
            generatedPassword = characters.joined()
            currentPasswordEntropy = viewModel.calculatePasswordEntropy(password: characters.joined())
        })
        
        .onAppear(perform: {
            characters = viewModel.generatePassword(lenght: Int(characterCount), specialCharacters: specialCharacters, uppercase: uppercased, numbers: withNumbers)
            generatedPassword = characters.joined()
            currentPasswordEntropy = viewModel.calculatePasswordEntropy(password: characters.joined())
            
        })
    }
    
   private func animationDisappear() {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            passwordViewModel.showAnimation = false
            print("Show animation")
        }
    }
    
   private func clipBoardAnimationDisapear() {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            clipboardSaveAnimation = false
            print("Show animation")
        }
    }
}



struct PasswordGeneratorView_Previews: PreviewProvider {
    static var previews: some View {
        PasswordGeneratorView(settings: SettingsViewModel(), passwordViewModel: PasswordListViewModel())
    }
}

