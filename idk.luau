local RunService         = game:GetService("RunService")
	local Library = {
		Connections = {}, Flags = {}, Shutdown = false,
		Settings = {Elements = {ShowSliderMax = false}, GroupTransparency = 0.05},
		icons = {
			BoxEye = "rbxassetid://16095745843",
			Person = "http://www.roblox.com/asset/?id=10897014055",
			Crosshair = "rbxassetid://12967713729",
			Rage = "rbxassetid://12974399858",
			Storm = "rbxassetid://11326879610",
			Sword = "rbxassetid://16095745917",

			Waypoint = "http://www.roblox.com/asset/?id=6031154875",
			Shield = "http://www.roblox.com/asset/?id=6034837802",
			Connection = "http://www.roblox.com/asset/?id=6031229350",
			Car = "http://www.roblox.com/asset/?id=6034754441"
		},
	}



	local buttonsbfsa = {}


	local function Create(Name, Properties, Children)
		local Object = Instance.new(tostring(Name))
		for i, v in next, Properties or {} do
			Object[tostring(i)] = v
		end
		for i, v in next, Children or {} do
			v.Parent = Object
		end

		return Object
	end


	local function AddConnection(Signal, Function)
		if (not Library:IsRunning()) then return end
		local Connection = Signal:Connect(Function)
		table.insert(Library.Connections, Connection)
		return Connection
	end

	local function Round(Number, Factor)
		local Result = math.floor(Number/Factor + (math.sign(Number) * 0.5)) * Factor
		if Result < 0 then Result = Result + Factor end
		return Result
	end


	local WhitelistedMouse = {Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2,Enum.UserInputType.MouseButton3}
	local BlacklistedKeys = {Enum.KeyCode.Unknown,Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D,Enum.KeyCode.Up,Enum.KeyCode.Left,Enum.KeyCode.Down,Enum.KeyCode.Right,Enum.KeyCode.Slash,Enum.KeyCode.Tab,Enum.KeyCode.Backspace,Enum.KeyCode.Escape}

	local function CheckKey(Table, Key)
		for _, v in next, Table do
			if v == Key then
				return true
			end
		end
	end

	pcall(function()
		if Library.GUI then Library.GUI:Destroy() end
	end)

	local GUI = Create("ScreenGui", {
		Parent = game:GetService("CoreGui"),
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	})

	function Library:IsRunning()
		return GUI.Parent == RunService:IsStudio() and LocalPlayer.PlayerGui or game:GetService("CoreGui")
	end

	function Library:Open(main)
		TweenService:Create(main, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {GroupTransparency = 1 or 0}):Play()
		TweenService:Create(main.UIStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Transparency = Library.GUI.Enabled and 1 or 0}):Play()
		task.wait(.25)
		Library.GUI:Destroy()
	end

	function Library:Close(main)
		TweenService:Create(main, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {GroupTransparency = Library.GUI.Enabled and 1 or 0}):Play()
		TweenService:Create(main.UIStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Transparency = Library.GUI.Enabled and 1 or 0}):Play()
		task.wait(.25)
		Library.GUI:Destroy()
	end

	local function MakeDraggable(DragPoint, Main)
		pcall(function()
			local Dragging, DragInput, MousePos, FramePos = false
			AddConnection(DragPoint.InputBegan, function(Input)
				if Input.UserInputType == Enum.UserInputType.MouseButton1 then
					Dragging = true
					MousePos = Input.Position
					FramePos = Main.Position

					AddConnection(Input.Changed, function()
						if Input.UserInputState == Enum.UserInputState.End then
							Dragging = false
						end
					end)
				end
			end)
			AddConnection(DragPoint.InputChanged, function(Input)
				if Input.UserInputType == Enum.UserInputType.MouseMovement then
					DragInput = Input
				end
			end)
			AddConnection(UserInputService.InputChanged, function(Input)
				if Input == DragInput and Dragging then
					local Delta = Input.Position - MousePos
					TweenService:Create(Main, TweenInfo.new(.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(FramePos.X.Scale,FramePos.X.Offset + Delta.X, FramePos.Y.Scale, FramePos.Y.Offset + Delta.Y)}):Play()
				end
			end)
		end)
	end


	task.spawn(function()
		Library.GUI = GUI
		while (Library:IsRunning()) do wait() end
		for _, Connection in next, Library.Connections do Connection:Disconnect() end
	end)

	function Library.Load(configs)
		configs = configs or {}
		configs.Title = configs.Title or "Online"
		configs.greenText = configs.greenText

		local sectionButton;
		
		local settingsButton;

		local searchBar;
		local searchLog = {}	
		
		local searchContainer;
		local lastActive;

		local MainUI = Create("CanvasGroup", {
			Name = "Main UI",
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(17, 17, 17),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(650, 500),
			Visible = true,
			Parent = Library.GUI,
			ClipsDescendants = true,
			GroupTransparency = 0.05,
			ZIndex = 0
		}, {

			Create("Frame", {
				Name = "SettingsTabHolder",
				Active = true,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(15, 15, 15),
				BackgroundTransparency = 0.150,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				ClipsDescendants = true,
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(1, 0, 1, 0),
				Visible = true,
				ZIndex = 2,
			}, {
				Create("Frame", {
					Name = "Settings",
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromRGB(21, 21, 21),
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.new(0.5, 0, 0.5, 0),
					Size = UDim2.new(0.800000012, 0, 0.75, 0)
				}, {
					Create("TextButton", {
						Name = "returnScript",
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = Color3.fromRGB(11, 123, 82),
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Size = UDim2.new(0.9, 0, 0, 25),
						Text = "",
						TextColor3 = Color3.fromRGB(0, 0, 0),
						TextSize = 14,
						AutoButtonColor = true,
						Position = UDim2.new(0.5, 0,0.9, 0)
					}, {
						Create("TextLabel", {
							Name = "name",
							AnchorPoint = Vector2.new(0.5, 0.5),
							BackgroundColor3 = Color3.fromRGB(255, 255, 255),
							BackgroundTransparency = 1,
							BorderColor3 = Color3.fromRGB(0, 0, 0),
							BorderSizePixel = 0,
							FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
							Position = UDim2.fromScale(0.5, 0.5),
							Size = UDim2.fromOffset(381, 16),
							Text = "Back to script",
							TextColor3 = Color3.fromRGB(234, 234, 234),
							TextSize = 14,
							TextTruncate = Enum.TextTruncate.AtEnd,
						}),
						Create("UICorner",{
							CornerRadius=UDim.new(0,2)	
						}),
						Create("UIStroke", {
							ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
							Color = Color3.fromRGB(14, 157, 105),
						})
					}),
					Create("Frame", {
						Name = "Sections",
						BackgroundColor3 = Color3.fromRGB(255, 0, 0),
						BackgroundTransparency = 1.000,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						Size = UDim2.new(1, 0, 0, 0)
					}, {
						Create("UIListLayout", {
							Padding = UDim.new(0, 8),
							SortOrder = Enum.SortOrder.LayoutOrder,
							HorizontalAlignment = Enum.HorizontalAlignment.Center
						}),
						Create("Frame", {
							BackgroundColor3 = Color3.fromRGB(255, 255, 255),
							BackgroundTransparency = 1,
							BorderColor3 = Color3.fromRGB(0, 0, 0),
							BorderSizePixel = 0,
							Size = UDim2.new(1, 0, 0, 26),
						}, {
							Create("TextLabel", {
								Name = "namesection",
								AutomaticSize = Enum.AutomaticSize.X,
								BackgroundColor3 = Color3.fromRGB(21,21,21),
								BorderColor3 = Color3.fromRGB(0, 0, 0),
								BorderSizePixel = 0,
								FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
								Size = UDim2.fromOffset(66, 24),
								Text = "Settings",
								TextColor3 = Color3.fromRGB(85, 85, 85),
								TextSize = 14,
								ZIndex = 2
							}, {
								Create("UIPadding", {
									PaddingLeft = UDim.new(0, 8),
									PaddingRight = UDim.new(0, 8)
								})	
							}),
							Create("Frame", {
								AnchorPoint = Vector2.new(0.5, 0.5),
								BackgroundColor3 = Color3.fromRGB(30, 30, 30),
								BorderColor3 = Color3.fromRGB(0, 0, 0),
								BorderSizePixel = 0,
								Position = UDim2.fromScale(0.5, 0.5),
								Size = UDim2.new(1, 0, 0, 1)
							})
						}),
						Create("Frame", {
							Name = "ElementHolder",
							BackgroundColor3 = Color3.fromRGB(255, 255, 255),
							BackgroundTransparency = 1.000,
							BorderColor3 = Color3.fromRGB(0, 0, 0),
							BorderSizePixel = 0,
							Size = UDim2.new(1, 0, 0, 0),
							AutomaticSize = Enum.AutomaticSize.Y
						}, {
							Create("UIListLayout", {
								Padding = UDim.new(0, 8),
								HorizontalAlignment = Enum.HorizontalAlignment.Center,
								SortOrder = Enum.SortOrder.LayoutOrder
							}),
						})
					})

				})

			}),
			Create("Folder", {
				Name = "Containers"	
			}, {
				Create("ScrollingFrame", {
					Name = "Search Tab Holder",
					Active = true,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.fromOffset(226, 52),
					ScrollBarImageColor3 = Color3.fromRGB(116, 116, 116),
					ScrollBarImageTransparency = 0.33,
					ScrollBarThickness = 2,
					Size = UDim2.fromOffset(423, 414),
					ZIndex = 3,
					Visible = false
				}, {
					Create("UIListLayout", {
						Padding = UDim.new(0, 8),
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),
					Create("Frame", {
						Name = "Section",
						AutomaticSize = Enum.AutomaticSize.Y,
						BackgroundColor3 = Color3.fromRGB(255, 0, 0),
						BackgroundTransparency = 1,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						Size = UDim2.fromScale(1, 0),
					}, {
						Create("UIListLayout", {
							Padding = UDim.new(0, 8),
							SortOrder = Enum.SortOrder.LayoutOrder
						}),
						Create("Frame", {
							Name = "Elements Holder search bar",
							AutomaticSize = Enum.AutomaticSize.Y,
							BackgroundColor3 = Color3.fromRGB(255, 255, 255),
							BackgroundTransparency = 1,
							BorderColor3 = Color3.fromRGB(0, 0, 0),
							BorderSizePixel = 0,
							Size = UDim2.fromScale(1, 0),
						}, {
							Create("UIListLayout", {
								Padding = UDim.new(0, 8),
								HorizontalAlignment = Enum.HorizontalAlignment.Center,
								SortOrder = Enum.SortOrder.LayoutOrder
							}),
						}),
						Create("Frame", {
							BackgroundColor3 = Color3.fromRGB(255, 255, 255),
							BackgroundTransparency = 1,
							BorderColor3 = Color3.fromRGB(0, 0, 0),
							BorderSizePixel = 0,
							Size = UDim2.new(1, 0, 0, 26),
						}, {
							Create("TextLabel", {
								Name = "namesection",
								AutomaticSize = Enum.AutomaticSize.X,
								BackgroundColor3 = Color3.fromRGB(17, 17, 17),
								BorderColor3 = Color3.fromRGB(0, 0, 0),
								BorderSizePixel = 0,
								FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
								Size = UDim2.fromOffset(66, 24),
								Text = "Search!",
								TextColor3 = Color3.fromRGB(85, 85, 85),
								TextSize = 14,
								ZIndex = 2
							}, {
								Create("UIPadding", {
									PaddingLeft = UDim.new(0, 8),
									PaddingRight = UDim.new(0, 8)
								})	
							}),
							Create("Frame", {
								AnchorPoint = Vector2.new(0.5, 0.5),
								BackgroundColor3 = Color3.fromRGB(30, 30, 30),
								BorderColor3 = Color3.fromRGB(0, 0, 0),
								BorderSizePixel = 0,
								Position = UDim2.fromScale(0.5, 0.5),
								Size = UDim2.new(1, 0, 0, 1)
							})

						})
					})
				})
			}),
			Create("UICorner", {
				CornerRadius = UDim.new(0,8)
			}),
			Create("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = Color3.fromRGB(29, 29, 29)
			}),
			Create("Frame", {
				Name = "Bottom Menu",
				BackgroundColor3 = Color3.fromRGB(21, 21, 21),
				BorderColor3 = Color3.fromRGB(29, 29, 29),
				Position = UDim2.new(0.345, 1, 0.94, 0),
				Size = UDim2.fromOffset(424, 30)
			}, {
				Create("TextLabel", {
					BackgroundColor3 = Color3.fromRGB(97, 97, 97),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
					Position = UDim2.fromOffset(10, 0),
					Size = UDim2.fromOffset(200, 30),
					Text = configs.Title,
					TextColor3 = Color3.fromRGB(97, 97, 97),
					TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Left,
				}),
				Create("TextLabel", {
					Name = "ver",
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundColor3 = Color3.fromRGB(97, 97, 97),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
					Position = UDim2.new(1, -10, 0.5, 0),
					Size = UDim2.fromOffset(11, 30),
					Text = configs.greenText,
					TextColor3 = Color3.fromRGB(7, 157, 103),
					TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Right
				})
			}),
			Create("Frame", {
				Name = "tabsTopHolder",
				BackgroundColor3 = Color3.fromRGB(21, 21, 21),
				BorderColor3 = Color3.fromRGB(29, 29, 29),
				Position = UDim2.new(0.34, 4, 0, 0),
				Size = UDim2.fromOffset(424, 50)
			}, {
				Create("TextBox", {
					Name = "SearchBar",
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundColor3 = Color3.fromRGB(25, 25, 25),
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
					PlaceholderColor3 = Color3.fromRGB(96, 96, 96),
					PlaceholderText = "Search",
					Position = UDim2.new(1, -7, 0.5, 0),
					Size = UDim2.fromOffset(150, 36),
					Text = "",
					TextColor3 = Color3.fromRGB(232, 232, 232),
					TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Left
				}, {
					Create("UICorner", {
						CornerRadius = UDim.new(0,8)	
					}),
					Create("UIStroke", {
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
						Color = Color3.fromRGB(31, 31, 31)
					}),
					Create("UIPadding", {
						PaddingLeft = UDim.new(0, 10),
						PaddingRight = UDim.new(0, 10)
					})
				}),

				Create("ScrollingFrame", {
					Active = true,
					Name = "tabsTopScrollingFrame",
					AutomaticCanvasSize = Enum.AutomaticSize.X,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					BottomImage = "",
					Position = UDim2.fromOffset(8, 0),
					ScrollBarImageColor3 = Color3.fromRGB(0, 0, 0),
					ScrollBarThickness = 0,
					ScrollingDirection = Enum.ScrollingDirection.X,
					Size = UDim2.fromOffset(249, 50),
					TopImage = ""
				}, {
					Create("TextButton", {
						Name = "SectionBtn",
						AutoButtonColor = false,
						AnchorPoint = Vector2.new(.5, 0.5),
						AutomaticSize = Enum.AutomaticSize.X,
						BackgroundColor3 = Color3.fromRGB(25, 25, 25),
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.25, .25),
						Size = UDim2.fromOffset(89, 36),
						Text = "",
						TextColor3 = Color3.fromRGB(0, 0, 0),
						TextSize = 14
					}, {
						Create("UICorner", {
							CornerRadius = UDim.new(0,8)	
						}),
						Create("UIStroke", {
							ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
							Color = Color3.fromRGB(29, 29, 29)
						}),
						Create("TextLabel", {
							Name = "name",
							AnchorPoint = Vector2.new(0, 0.5),
							AutomaticSize = Enum.AutomaticSize.X,
							BackgroundColor3 = Color3.fromRGB(240, 240, 240),
							BackgroundTransparency = 1,
							BorderColor3 = Color3.fromRGB(0, 0, 0),
							BorderSizePixel = 0,
							FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
							Position = UDim2.fromScale(0, 0.5),
							Size = UDim2.fromOffset(50, 26),
							Text = "Script Section",
							TextColor3 = Color3.fromRGB(240, 240, 240),
							TextSize = 14,
							TextXAlignment = Enum.TextXAlignment.Left
						}, {
							Create("UIPadding", {
								PaddingLeft = UDim.new(0, 10),
								PaddingRight = UDim.new(0, 10)
							})
						})

					}),
					Create("TextButton", {
						Name = "SettingsBtn",
						AutoButtonColor = false,
						AnchorPoint = Vector2.new(.5, 0.5),
						AutomaticSize = Enum.AutomaticSize.X,
						BackgroundColor3 = Color3.fromRGB(25, 25, 25),
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Position = UDim2.fromScale(0.75, .25),
						Size = UDim2.fromOffset(89, 36),
						Text = "",
						TextColor3 = Color3.fromRGB(0, 0, 0),
						TextSize = 14,
						BackgroundTransparency = 1
					}, {
						Create("UICorner", {
							CornerRadius = UDim.new(0,8)	
						}),
						Create("UIStroke", {
							ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
							Color = Color3.fromRGB(29, 29, 29),
							Transparency = 1
						}),
						Create("TextLabel", {
							Name = "name",
							AnchorPoint = Vector2.new(0, 0.5),
							AutomaticSize = Enum.AutomaticSize.X,
							BackgroundColor3 = Color3.fromRGB(240, 240, 240),
							BackgroundTransparency = 1,
							BorderColor3 = Color3.fromRGB(0, 0, 0),
							BorderSizePixel = 0,
							FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
							Position = UDim2.fromScale(0, 0.5),
							Size = UDim2.fromOffset(50, 26),
							Text = "Settings Section",
							TextColor3 = Color3.fromRGB(97, 97, 97),
							TextSize = 14,
							TextXAlignment = Enum.TextXAlignment.Left
						}, {
							Create("UIPadding", {
								PaddingLeft = UDim.new(0, 10),
								PaddingRight = UDim.new(0, 10)
							})
						})

					}),
				})
			}),
			Create("Frame", {
				Name = "tabsButtonHolder",
				BackgroundColor3 = Color3.fromRGB(21, 21, 21),
				BorderColor3 = Color3.fromRGB(29, 29, 29),
				Size = UDim2.new(0.099, 160, 1, 0)
			}, {
				Create("UIPadding", {
					Name = "UIPadding",
					PaddingBottom = UDim.new(0, 1),
					PaddingRight = UDim.new(0, 1),
					PaddingTop = UDim.new(0, 1),
				}),
				Create("ScrollingFrame", {
					Name = "scrollingHolder",
					Active = true,
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					BottomImage = "",
					CanvasSize = UDim2.new(),
					ScrollBarImageColor3 = Color3.fromRGB(135, 135, 135),
					ScrollBarImageTransparency = 0.5,
					ScrollBarThickness = 2,
					Size = UDim2.fromScale(1, 1),
					TopImage = ""
				}, {
					Create("UIListLayout", {
						Padding = UDim.new(0, 8),
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),
					Create("UIPadding", {
						Name = "UIPadding",
						PaddingBottom = UDim.new(0, 8),
						PaddingLeft = UDim.new(0, 8),
						PaddingRight = UDim.new(0, 7),
						PaddingTop = UDim.new(0, 8)
					}),
					Create("Frame", {
						Name = "buttonsHolder",
						AutomaticSize = Enum.AutomaticSize.Y,
						BackgroundColor3 = Color3.fromRGB(255, 0, 0),
						BackgroundTransparency = 1,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						Size = UDim2.fromScale(1, 0)
					}, {
						Create("UIListLayout", {
							Padding = UDim.new(0, 8),
							SortOrder = Enum.SortOrder.LayoutOrder,
						}),
					})
				})
			})
		})
		task.spawn(function()
			local elementsHolder = MainUI.SettingsTabHolder.Settings.Sections.ElementHolder
			do
				local toggle = {Value = configs.Default, Type = "Toggle"}
				local Toggle = Create("TextButton", {
					Name = "FPS UNLOCKER",
					AutoButtonColor = false,
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
					Position = UDim2.fromScale(0, 0.519),
					Size = UDim2.fromScale(1, 0),
					Text = "",
					TextColor3 = Color3.fromRGB(0, 0, 0),
					TextSize = 14,
					Parent = elementsHolder
				}, {
					Create("UIPadding", {
						Name = "UIPadding",
						PaddingBottom = UDim.new(0, 4),
						PaddingLeft = UDim.new(0, 10),
						PaddingRight = UDim.new(0, 10),
						PaddingTop = UDim.new(0, 4)
					}),

					Create("TextLabel", {
						Name = "name",
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
						Position = UDim2.new(0.0393, 8, 0, 0),
						Size = UDim2.fromOffset(381, 16),
						Text = "FPS unlocker",
						TextColor3 = Color3.fromRGB(234, 234, 234),
						TextSize = 14,
						TextTruncate = Enum.TextTruncate.AtEnd,
						TextXAlignment = Enum.TextXAlignment.Left
					}),

					Create("TextLabel", {
						Name = "description",
						AutomaticSize = Enum.AutomaticSize.Y,
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
						Position = UDim2.fromOffset(0, 23),
						RichText = true,
						Size = UDim2.new(1, 0, 0, 16),
						Text = "Uncap the amount of FPS",
						TextColor3 = Color3.fromRGB(154, 154, 154),
						TextSize = 14,
						TextWrapped = true,
						TextXAlignment = Enum.TextXAlignment.Left,
						Visible = true
					}),
					Create("Frame", {
						Name = "ToggleStatus",
						BackgroundColor3 = Color3.fromRGB(11, 123, 82),
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						Size = UDim2.fromOffset(16, 16)
					},{
						Create("UICorner", {
							CornerRadius = UDim.new(0, 2)	
						}),
						Create("ImageLabel", {
							Name = "Toggle Icon",
							AnchorPoint = Vector2.new(0.5, 0.5),
							BackgroundColor3 = Color3.fromRGB(255, 255, 255),
							BackgroundTransparency = 1,
							BorderColor3 = Color3.fromRGB(0, 0, 0),
							BorderSizePixel = 0,
							Image = "http://www.roblox.com/asset/?id=6031094667",
							ImageColor3 = Color3.fromRGB(17, 17, 17),
							Position = UDim2.fromScale(0.5, 0.5),
							Size = UDim2.fromOffset(12, 12)
						}),
						Create("UIStroke", {
							ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
							Color = Color3.fromRGB(36, 36, 36)
						})

					})
				})

				AddConnection(Toggle.MouseButton1Click, function()
					do
						print("fps unlocked")
					end

					toggle:Set(not toggle.Value)
					TweenService:Create(Toggle.ToggleStatus, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = toggle.Value and 0 or 1}):Play()
				end)

				function toggle:Set()
					self.Value = not self.Value
				end

				toggle:Set(toggle.Value)
			end
			do
				local toggle = {Value = false, Type = "Toggle"}
				local Toggle = Create("TextButton", {
					Name = "Save Settings",
					AutoButtonColor = false,
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
					Position = UDim2.fromScale(0, 0.519),
					Size = UDim2.fromScale(1, 0),
					Text = "",
					TextColor3 = Color3.fromRGB(0, 0, 0),
					TextSize = 14,
					Parent = elementsHolder
				}, {
					Create("UIPadding", {
						Name = "UIPadding",
						PaddingBottom = UDim.new(0, 4),
						PaddingLeft = UDim.new(0, 10),
						PaddingRight = UDim.new(0, 10),
						PaddingTop = UDim.new(0, 4)
					}),

					Create("TextLabel", {
						Name = "name",
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
						Position = UDim2.new(0.0393, 8, 0, 0),
						Size = UDim2.fromOffset(381, 16),
						Text = "Save settings",
						TextColor3 = Color3.fromRGB(234, 234, 234),
						TextSize = 14,
						TextTruncate = Enum.TextTruncate.AtEnd,
						TextXAlignment = Enum.TextXAlignment.Left
					}),

					Create("TextLabel", {
						Name = "description",
						AutomaticSize = Enum.AutomaticSize.Y,
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
						Position = UDim2.fromOffset(0, 23),
						RichText = true,
						Size = UDim2.new(1, 0, 0, 16),
						Text = "Uncap the amount of FPS",
						TextColor3 = Color3.fromRGB(154, 154, 154),
						TextSize = 14,
						TextWrapped = true,
						TextXAlignment = Enum.TextXAlignment.Left,
						Visible = false
					}),
					Create("Frame", {
						Name = "ToggleStatus",
						BackgroundColor3 = Color3.fromRGB(11, 123, 82),
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						Size = UDim2.fromOffset(16, 16)
					},{
						Create("UICorner", {
							CornerRadius = UDim.new(0, 2)	
						}),
						Create("ImageLabel", {
							Name = "Toggle Icon",
							AnchorPoint = Vector2.new(0.5, 0.5),
							BackgroundColor3 = Color3.fromRGB(255, 255, 255),
							BackgroundTransparency = 1,
							BorderColor3 = Color3.fromRGB(0, 0, 0),
							BorderSizePixel = 0,
							Image = "http://www.roblox.com/asset/?id=6031094667",
							ImageColor3 = Color3.fromRGB(17, 17, 17),
							Position = UDim2.fromScale(0.5, 0.5),
							Size = UDim2.fromOffset(12, 12)
						}),
						Create("UIStroke", {
							ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
							Color = Color3.fromRGB(36, 36, 36)
						})

					})
				})

				AddConnection(Toggle.MouseButton1Click, function()
					toggle:Set(not toggle.Value)
					TweenService:Create(Toggle.ToggleStatus, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = toggle.Value and 0 or 1}):Play()
				end)

				function toggle:Set()
					self.Value = not self.Value
				end

				toggle:Set(toggle.Value)
			end
			do
				local configs = {}
				local Slider = {Value = 5, Type = "Slider"}
				local Dragging = false

				configs.Name = "Change UI Transparency"
				configs.Default = configs.Default or 5

				configs.Callback = function()
					MainUI.GroupTransparency = Slider.Value/100
				end

				configs.Description = true
				configs.DescriptionText = "Change UI Transparency"

				configs.Min = 0
				configs.Max = 10
				configs.Increment = 1


				local entireHolding = Create("TextButton", {
					Name = "Change UI Transparency",
					Parent = elementsHolder,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1.000,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.new(0, 0, 0.519230783, 0),
					Size = UDim2.new(1, 0, 0, 40),
					AutoButtonColor = false,
					Font = Enum.Font.SourceSans,
					AutomaticSize = Enum.AutomaticSize.Y,
					Text = "",
					TextColor3 = Color3.fromRGB(0, 0, 0),
					TextSize = 14.000
				}, {
					Create("UIPadding", {
						PaddingBottom = UDim.new(0,4),
						PaddingLeft = UDim.new(0,10),
						PaddingRight = UDim.new(0,10),
						PaddingTop = UDim.new(0,4)
					}),
					Create("TextLabel", {
						Name = "name",
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1.000,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						Position = UDim2.new(-0.0196560472, 8, 0, 0),
						Size = UDim2.new(0, 312, 0, 16),
						Font = Enum.Font.Gotham,
						Text = configs.Name,
						TextColor3 = Color3.fromRGB(234, 234, 234),
						TextSize = 14.000,
						TextXAlignment = Enum.TextXAlignment.Left
					}),
					Create("TextLabel", {
						Name = "description",
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1.000,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						Position = UDim2.new(0, 0, 0, 38),
						Size = UDim2.new(1, 0, 0, 16),
						Font = Enum.Font.Gotham,
						Text = configs.DescriptionText,
						TextColor3 = Color3.fromRGB(154, 154, 154),
						TextSize = 14.000,
						TextWrapped = true,
						TextXAlignment = Enum.TextXAlignment.Left
					})
				})

				local ValueText = Create("TextLabel", {
					Name = "value",
					Parent = entireHolding,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1.000,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.new(0.754537523, 8, 0, 0),
					Size = UDim2.new(0, 90, 0, 16),
					Font = Enum.Font.Gotham,
					Text = Slider.Value,
					TextColor3 = Color3.fromRGB(234, 234, 234),
					TextSize = 14.000,
					TextXAlignment = Enum.TextXAlignment.Right
				})

				local SliderFrame = Create("Frame", {
					Parent = entireHolding,
					AnchorPoint = Vector2.new(0.5, 0),
					BackgroundColor3 = Color3.fromRGB(21, 21, 21),
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.new(0.5, 0, 0, 26),
					Size = UDim2.new(1, 0, 0, 2),
				}, {
					Create("UICorner", {
						CornerRadius = UDim.new(0,2)	
					}),
					Create("UIStroke", {
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
						Color = Color3.fromRGB(29, 29, 29)
					})
				})

				local SliderProgress = Create("Frame", {
					Name = "slideindicator",
					Parent = SliderFrame,
					AnchorPoint = Vector2.new(0, 0.5),
					BackgroundColor3 = Color3.fromRGB(11, 123, 82),
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.new(0, 0, 0.5, 0),
					Size = UDim2.new(0, 100, 1, 0)
				}, {	
					Create("UICorner", {
						CornerRadius = UDim.new(0,2)	
					}),
					Create("UIStroke", {
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
						Color = Color3.fromRGB(9, 144, 95)
					})
				})

				local SliderDot = Create("TextButton", {
					Name = "slidethumb",
					Parent = SliderFrame,
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundColor3 = Color3.fromRGB(11, 123, 82),
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.new(1, 5, 0.5, 0),
					Size = UDim2.new(0, 10, 0, 10),
					Text = ""
				}, {	
					Create("UICorner", {
						CornerRadius = UDim.new(1,0)	
					}),
					Create("UIStroke", {
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
						Color = Color3.fromRGB(9, 144, 95)
					})
				})
				AddConnection(UserInputService.InputChanged, function(Input)
					if Dragging and Input.UserInputType == Enum.UserInputType.MouseMovement then 
						local SizeScale = math.clamp((Input.Position.X - SliderFrame.AbsolutePosition.X) / SliderFrame.AbsoluteSize.X, 0, 1)
						Slider:Set(configs.Min + ((configs.Max - configs.Min) * SizeScale)) 
					end
				end)

				AddConnection(SliderDot.InputBegan, function(Input)
					if Input.UserInputType == Enum.UserInputType.MouseButton1 then 
						Dragging = true;
					end 
				end)

				AddConnection(SliderDot.InputEnded, function(Input)
					if Input.UserInputType == Enum.UserInputType.MouseButton1 then 
						Dragging = false;
					end 
				end)
				function Slider:Set(Value)
					self.Value = math.clamp(Round(Value, configs.Increment), configs.Min, configs.Max)
					ValueText.Text = Library.Settings.Elements.ShowSliderMax and (tostring(self.Value).." / "..configs.Max) or tostring(self.Value)
					TweenService:Create(SliderDot,TweenInfo.new(.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),{Position = UDim2.new((self.Value - configs.Min) / (configs.Max - configs.Min), 5, SliderDot.Position.Y.Scale,SliderDot.Position.Y.Offset)}):Play()
					TweenService:Create(SliderProgress,TweenInfo.new(.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),{Size = UDim2.fromScale((self.Value - configs.Min) / (configs.Max - configs.Min), 1)}):Play()
					return configs.Callback()
				end
				Slider:Set(Slider.Value)
			end
			do
				local Bind = {Value = Enum.KeyCode.LeftControl, Binding = false, Type = "Bind"}
				local Holding = false

				local Keybind = Create("TextButton", {
					Name = "Toggle GUI Keybind",
					Parent = elementsHolder,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Position = UDim2.new(0, 0, 0.519230783, 0),
					Size = UDim2.new(1, 0, 0, 40),
					AutoButtonColor = false,
					Font = Enum.Font.SourceSans,
					Text = "",
					TextColor3 = Color3.fromRGB(0, 0, 0),
					TextSize = 14
				}, {
					Create("TextLabel", {
						Name = "name",
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						Position = UDim2.new(-0.0196560472, 8, 0, 0),
						Size = UDim2.new(0, 312, 0, 16),
						Font = Enum.Font.Gotham,
						Text = "Toggle GUI Keybind",
						TextColor3 = Color3.fromRGB(234, 234, 234),
						TextSize = 14,
						TextXAlignment = Enum.TextXAlignment.Left
					}),
					Create("UIPadding", {
						PaddingBottom = UDim.new(0, 4),
						PaddingLeft = UDim.new(0, 10),
						PaddingRight = UDim.new(0, 10),
						PaddingTop = UDim.new(0, 4)
					}),
					Create("TextLabel", {
						Name = "description",
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						Position = UDim2.new(0, 0, 0, 16),
						Size = UDim2.new(0.468982637, 0, 0, 16),
						Font = Enum.Font.Gotham,
						Text = "Select GUI toggle keybind",
						TextColor3 = Color3.fromRGB(154, 154, 154),
						TextSize = 14,
						TextWrapped = true,
						TextXAlignment = Enum.TextXAlignment.Left,
						Visible = true
					}),
					Create("TextLabel", {
						Name = "keybind_selected",
						Active = true,
						AnchorPoint = Vector2.new(1, 0.5),
						BackgroundColor3 = Color3.fromRGB(21, 21, 21),
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						Position = UDim2.new(1, 0, 0.5, 0),
						Size = UDim2.new(0, 0, 0, 25),
						Font = Enum.Font.Gotham,
						Text = "",
						TextColor3 = Color3.fromRGB(154, 154, 154),
						TextSize = 14,
						TextWrapped = true,
						TextXAlignment = Enum.TextXAlignment.Right,
						AutomaticSize = Enum.AutomaticSize.X,

					}, {
						Create("UIStroke", {
							ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
							Color = Color3.fromRGB(36, 36, 36)
						}),
						Create("UICorner", {
							CornerRadius = UDim.new(0, 2)	
						}),
						Create("UIPadding", {
							PaddingLeft = UDim.new(0,10),
							PaddingRight = UDim.new(0,10)
						})
					})
				})

				AddConnection(Keybind.InputEnded, function(Input)
					if Input.UserInputType == Enum.UserInputType.MouseButton1 then
						if Bind.Binding then return end
						Bind.Binding = true
						Keybind.keybind_selected.Text = "..."
					end
				end)

				AddConnection(UserInputService.InputBegan, function(Input)
					if UserInputService:GetFocusedTextBox() then return end
					if (Input.KeyCode.Name == Bind.Value or Input.UserInputType.Name == Bind.Value) and not Bind.Binding then
						Library.GUI.Enabled = not Library.GUI.Enabled
					elseif Bind.Binding then
						local Key
						pcall(function()
							if not CheckKey(BlacklistedKeys, Input.KeyCode) then
								Key = Input.KeyCode
							end
						end)
						pcall(function()
							if CheckKey(WhitelistedMouse, Input.UserInputType) and not Key then
								Key = Input.UserInputType
							end
						end)
						Key = Key or Bind.Value
						Bind:Set(Key)
					end
				end)

				AddConnection(UserInputService.InputEnded, function(Input)
					if Input.KeyCode.Name == Bind.Value or Input.UserInputType.Name == Bind.Value then
						if Holding then
							Holding = false
						end
					end
				end)


				function Bind:Set(Key)
					Bind.Binding = false
					Bind.Value = Key or Bind.Value
					Bind.Value = Bind.Value.Name or Bind.Value
					Keybind.keybind_selected.Text = Bind.Value
				end

				Bind:Set()
			end

			do
				local toggle = {Value = false, Type = "Toggle"}
				local Toggle = Create("TextButton", {
					Name = "Show slider max",
					AutoButtonColor = false,
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
					Position = UDim2.fromScale(0, 0.519),
					Size = UDim2.fromScale(1, 0),
					Text = "",
					TextColor3 = Color3.fromRGB(0, 0, 0),
					TextSize = 14,
					Parent = elementsHolder
				}, {
					Create("UIPadding", {
						Name = "UIPadding",
						PaddingBottom = UDim.new(0, 4),
						PaddingLeft = UDim.new(0, 10),
						PaddingRight = UDim.new(0, 10),
						PaddingTop = UDim.new(0, 4)
					}),

					Create("TextLabel", {
						Name = "name",
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
						Position = UDim2.new(0.0393, 8, 0, 0),
						Size = UDim2.fromOffset(381, 16),
						Text = "Show Sliders max value",
						TextColor3 = Color3.fromRGB(234, 234, 234),
						TextSize = 14,
						TextTruncate = Enum.TextTruncate.AtEnd,
						TextXAlignment = Enum.TextXAlignment.Left
					}),

					Create("TextLabel", {
						Name = "description",
						AutomaticSize = Enum.AutomaticSize.Y,
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
						Position = UDim2.fromOffset(0, 23),
						RichText = true,
						Size = UDim2.new(1, 0, 0, 16),
						Text = "Sliders will now show their max value aswell.",
						TextColor3 = Color3.fromRGB(154, 154, 154),
						TextSize = 14,
						TextWrapped = true,
						TextXAlignment = Enum.TextXAlignment.Left,
						Visible = false
					}),
					Create("Frame", {
						Name = "ToggleStatus",
						BackgroundColor3 = Color3.fromRGB(11, 123, 82),
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						Size = UDim2.fromOffset(16, 16)
					},{
						Create("UICorner", {
							CornerRadius = UDim.new(0, 2)	
						}),
						Create("ImageLabel", {
							Name = "Toggle Icon",
							AnchorPoint = Vector2.new(0.5, 0.5),
							BackgroundColor3 = Color3.fromRGB(255, 255, 255),
							BackgroundTransparency = 1,
							BorderColor3 = Color3.fromRGB(0, 0, 0),
							BorderSizePixel = 0,
							Image = "http://www.roblox.com/asset/?id=6031094667",
							ImageColor3 = Color3.fromRGB(17, 17, 17),
							Position = UDim2.fromScale(0.5, 0.5),
							Size = UDim2.fromOffset(12, 12)
						}),
						Create("UIStroke", {
							ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
							Color = Color3.fromRGB(36, 36, 36)
						})

					})
				})

				AddConnection(Toggle.MouseButton1Click, function()
					toggle:Set(not toggle.Value)
					TweenService:Create(Toggle.ToggleStatus, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = toggle.Value and 0 or 1}):Play()
					Library.Settings.Elements.ShowSliderMax = toggle.Value
				end)

				function toggle:Set()
					self.Value = not self.Value
				end

				toggle:Set(toggle.Value)
			end

			do
				local configs = {}
				configs.Name = "Unload script"
				configs.Callback = function() Library:Close(MainUI) end 

				configs.Accented = false
				local Button;

				if configs.Accented then
					Button = Create("TextButton", {
						Name = configs.Name,
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = Color3.fromRGB(11, 123, 82),
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Size = UDim2.new(0.9, 0, 0, 25),
						Text = "",
						TextColor3 = Color3.fromRGB(0, 0, 0),
						TextSize = 14,
						Parent = elementsHolder,
						AutoButtonColor = true,
					}, {
						Create("TextLabel", {
							Name = "name",
							AnchorPoint = Vector2.new(0.5, 0.5),
							BackgroundColor3 = Color3.fromRGB(255, 255, 255),
							BackgroundTransparency = 1,
							BorderColor3 = Color3.fromRGB(0, 0, 0),
							BorderSizePixel = 0,
							FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
							Position = UDim2.fromScale(0.5, 0.5),
							Size = UDim2.fromOffset(381, 16),
							Text = configs.Name,
							TextColor3 = Color3.fromRGB(234, 234, 234),
							TextSize = 14,
							TextTruncate = Enum.TextTruncate.AtEnd,
							Parent = Button
						}),
						Create("UICorner",{
							CornerRadius=UDim.new(0,2)	
						}),
						Create("UIStroke", {
							ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
							Color = Color3.fromRGB(14, 157, 105),
						})
					})
				else
					Button = Create("TextButton", {
						Name = configs.Name,
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = Color3.fromRGB(21, 21, 21),
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Size = UDim2.new(0.9, 0, 0, 25),
						Text = "",
						TextColor3 = Color3.fromRGB(0, 0, 0),
						TextSize = 14,
						Parent = elementsHolder,
						AutoButtonColor = true
					}, {
						Create("TextLabel", {
							Name = "name",
							AnchorPoint = Vector2.new(0.5, 0.5),
							BackgroundColor3 = Color3.fromRGB(255, 255, 255),
							BackgroundTransparency = 1,
							BorderColor3 = Color3.fromRGB(0, 0, 0),
							BorderSizePixel = 0,
							FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
							Position = UDim2.fromScale(0.5, 0.5),
							Size = UDim2.fromOffset(381, 16),
							Text = configs.Name,
							TextColor3 = Color3.fromRGB(234, 234, 234),
							TextSize = 14,
							TextTruncate = Enum.TextTruncate.AtEnd,
							Parent = Button
						}),
						Create("UICorner",{
							CornerRadius=UDim.new(0,2)	
						}),
						Create("UIStroke", {
							ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
							Color = Color3.fromRGB(36, 36, 36),
						})
					})
				end

				AddConnection(Button.MouseButton1Click, function()
					configs.Callback()
				end)
			end


		end)


		task.spawn(function()
			MakeDraggable(MainUI, MainUI)
			searchBar = MainUI.tabsTopHolder.SearchBar
			searchContainer = MainUI.Containers["Search Tab Holder"]

			for i,btn in next, MainUI.tabsTopHolder.tabsTopScrollingFrame:GetChildren() do
				if btn:IsA("TextButton") then
					if btn.Name == "SettingsBtn" then
						settingsButton = btn
					else
						sectionButton = btn
					end
					AddConnection(btn.MouseButton1Click, function()
						if (btn) == sectionButton then
							TweenService:Create(settingsButton, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
							TweenService:Create(settingsButton.UIStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Transparency = 1}):Play()
							TweenService:Create(settingsButton.name, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(97, 97, 97)}):Play()
							TweenService:Create(sectionButton, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
							TweenService:Create(sectionButton.UIStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Transparency = 0}):Play()
							TweenService:Create(sectionButton.name, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(240, 240, 240)}):Play()
							MainUI.SettingsTabHolder.Visible = false
						else
							TweenService:Create(sectionButton, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
							TweenService:Create(sectionButton.UIStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Transparency = 1}):Play()
							TweenService:Create(sectionButton.name, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(97, 97, 97)}):Play()
							TweenService:Create(settingsButton, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
							TweenService:Create(settingsButton.UIStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Transparency = 0}):Play()
							TweenService:Create(settingsButton.name, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(240, 240, 240)}):Play()
							MainUI.SettingsTabHolder.Visible = true
						end
					end)
				end
			end

			AddConnection(MainUI.SettingsTabHolder.Settings.returnScript.MouseButton1Click, function()
				MainUI.SettingsTabHolder.Visible = false

				TweenService:Create(settingsButton, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
				TweenService:Create(settingsButton.UIStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Transparency = 1}):Play()
				TweenService:Create(settingsButton.name, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(97, 97, 97)}):Play()
				TweenService:Create(sectionButton, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
				TweenService:Create(sectionButton.UIStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Transparency = 0}):Play()
				TweenService:Create(sectionButton.name, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(240, 240, 240)}):Play()
			end)

			AddConnection(searchBar:GetPropertyChangedSignal("Text"), function()
				local searchText = string.lower(searchBar.Text)
				searchContainer:FindFirstChild("namesection", true).Text = searchText

				if searchText == "" then
					searchContainer:FindFirstChild("namesection", true).Text = "Search!"	
				end

				for i,v in next, MainUI:GetDescendants() do
					if string.find(string.lower(v.Name), searchText) and (v.Parent.Name == "Elements Holder") and #searchText > 3 then
						searchLog[v] = {
							layoutOrder = v.LayoutOrder,
							parent = v.Parent,
						}
						v.Parent = MainUI.Containers["Search Tab Holder"]:FindFirstChild("Elements Holder search bar", true)
					end
				end
			end)

			AddConnection(searchBar.Focused, function()
				for i,v in next, MainUI.Containers:GetChildren() do
					if v.Visible then
						lastActive = v 
						v.Visible = false
						MainUI.Containers["Search Tab Holder"].Visible = true
					end
				end
			end)

			AddConnection(searchBar.FocusLost, function()
				for element, data in pairs(searchLog) do
					element.LayoutOrder = data.layoutOrder
					element.Parent = data.parent
				end

				searchLog = {}
				lastActive.Visible = true

				MainUI.Containers["Search Tab Holder"].Visible = false
				lastActive = nil
				searchContainer:FindFirstChild("namesection", true).Text = "Search!"
			end)	
		end)
		return {
			AddSeperator = function(SeperatorTitle)
				Create("Frame", {
					BackgroundTransparency = 1,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 0, 26),
					Parent = MainUI.tabsButtonHolder.scrollingHolder.buttonsHolder
				}, {
					Create("TextLabel", {
						AutomaticSize = Enum.AutomaticSize.X,
						BackgroundColor3 = Color3.fromRGB(21, 21, 21),
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
						Size = UDim2.fromOffset(0, 26),
						Text = SeperatorTitle,
						TextColor3 = Color3.fromRGB(85, 85, 85),
						TextSize = 14,
						ZIndex = 2
					}, {
						Create("UIPadding", {
							Name = "UIPadding",
							PaddingRight = UDim.new(0, 8)
						}),
					}),
					Create("Frame", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = Color3.fromRGB(30, 30, 30),
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						Position = UDim2.fromScale(0.5, 0.5),
						Size = UDim2.new(1, 0, 0, 1)
					})
				})
			end,
			AddTab = function(TabTitle, icon, first)
				local isFirst = first and true or false 
				local Icon = icon and icon or Library.icons.Person
				local tabButton;
				local tabHolder;
				tabButton = Create("TextButton", {
					Name = TabTitle,
					AutoButtonColor = false,
					BackgroundColor3 = Color3.fromRGB(25, 25, 25),
					BackgroundTransparency = isFirst and 0 or 1,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
					Size = UDim2.new(1, 0, 0, 36),
					Text = "",
					TextColor3 = Color3.fromRGB(0, 0, 0),
					TextSize = 14,
					Parent = MainUI.tabsButtonHolder.scrollingHolder.buttonsHolder
				}, {
					Create("UICorner", {
						CornerRadius = UDim.new(0,8)
					}),
					Create("UIStroke", {
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
						Color = Color3.fromRGB(29, 29, 29),
						Transparency = isFirst and 0 or 1
					}),
					Create("ImageLabel", {
						Name = "icon",
						AnchorPoint = Vector2.new(0, 0.5),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 1,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						Image = Icon,
						ImageColor3 = isFirst and Color3.fromRGB(6, 167, 109) or Color3.fromRGB(97, 97, 97),
						Position = UDim2.new(0, 7, 0.5, 0),
						Size = UDim2.fromOffset(24, 24)
					}),
					Create("TextLabel", {
						Name = "name",
						AnchorPoint = Vector2.new(1, 0.5),
						BackgroundColor3 = Color3.fromRGB(240, 240, 240),
						BackgroundTransparency = 1,
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
						Position = UDim2.fromScale(1, 0.5),
						Size = UDim2.fromOffset(169, 26),
						Text = TabTitle,
						TextColor3 = isFirst and Color3.fromRGB(240, 240, 240) or Color3.fromRGB(87, 87, 87),
						TextSize = 14,
						TextXAlignment = Enum.TextXAlignment.Left
					})
				})	

				tabHolder = Create("ScrollingFrame", {
					Name = "Tab holder",
					Active = true,
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = 1,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					CanvasSize = UDim2.new(),
					Position = UDim2.fromOffset(226, 52),
					ScrollBarImageColor3 = Color3.fromRGB(116, 116, 116),
					ScrollBarImageTransparency = 0.33,
					ScrollBarThickness = 2,
					Size = UDim2.fromOffset(423, 414),
					Parent = MainUI.Containers,
					Visible = isFirst and true or false
				}, {
					Create("UIListLayout", {
						Padding = UDim.new(0, 8),
						SortOrder = Enum.SortOrder.LayoutOrder
					})
				})


				AddConnection(tabButton.MouseButton1Click, function()
					for i,v in next, MainUI.tabsButtonHolder.scrollingHolder.buttonsHolder:GetChildren() do
						if v:IsA("TextButton") then
							local tabText = v:FindFirstChild("name")
							local tabStroke = v:FindFirstChild("UIStroke")
							local tabIcon = v:FindFirstChild("icon")
							TweenService:Create(v, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = v == tabButton and 0 or 1}):Play()
							TweenService:Create(tabText, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextColor3 = v == tabButton and Color3.fromRGB(240, 240, 240) or Color3.fromRGB(87, 87, 87)}):Play()
							TweenService:Create(tabIcon, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {ImageColor3 = v == tabButton and Color3.fromRGB(6, 167, 109) or Color3.fromRGB(87, 87, 87)}):Play()
							TweenService:Create(tabStroke, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Transparency = v == tabButton and 0 or 1}):Play()

						end
					end	
					for i,v in next, MainUI.Containers:GetChildren() do
						if v:IsA("ScrollingFrame") then
							v.Visible = v == tabHolder and true or false
						end
					end
				end)

				return {
					AddSection = function(SectionTitle)
						local Section = Create("Frame", {
							Name = "Section",
							AutomaticSize = Enum.AutomaticSize.Y,
							BackgroundColor3 = Color3.fromRGB(255, 0, 0),
							BackgroundTransparency = 1,
							BorderColor3 = Color3.fromRGB(0, 0, 0),
							BorderSizePixel = 0,
							Size = UDim2.fromScale(1, 0),
							Parent = tabHolder
						}, {
							Create("UIListLayout", {
								Padding = UDim.new(0, 8),
								SortOrder = Enum.SortOrder.LayoutOrder
							}),
							Create("Frame", {
								BackgroundColor3 = Color3.fromRGB(255, 255, 255),
								BackgroundTransparency = 1,
								BorderColor3 = Color3.fromRGB(0, 0, 0),
								BorderSizePixel = 0,
								Size = UDim2.new(1, 0, 0, 26),
							}, {
								Create("TextLabel", {
									Name = "namesection",
									AutomaticSize = Enum.AutomaticSize.X,
									BackgroundColor3 = Color3.fromRGB(17, 17, 17),
									BorderColor3 = Color3.fromRGB(0, 0, 0),
									BorderSizePixel = 0,
									FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
									Size = UDim2.fromOffset(66, 24),
									Text = SectionTitle,
									TextColor3 = Color3.fromRGB(85, 85, 85),
									TextSize = 14,
									ZIndex = 2
								}, {
									Create("UIPadding", {
										PaddingLeft = UDim.new(0, 8),
										PaddingRight = UDim.new(0, 8)
									})	
								}),
								Create("Frame", {
									AnchorPoint = Vector2.new(0.5, 0.5),
									BackgroundColor3 = Color3.fromRGB(30, 30, 30),
									BorderColor3 = Color3.fromRGB(0, 0, 0),
									BorderSizePixel = 0,
									Position = UDim2.fromScale(0.5, 0.5),
									Size = UDim2.new(1, 0, 0, 1)
								})

							})
						})

						local elementsHolder = Create("Frame", {
							Name = "Elements Holder",
							AutomaticSize = Enum.AutomaticSize.Y,
							BackgroundColor3 = Color3.fromRGB(255, 255, 255),
							BackgroundTransparency = 1,
							BorderColor3 = Color3.fromRGB(0, 0, 0),
							BorderSizePixel = 0,
							Size = UDim2.fromScale(1, 0),
							Parent = Section
						}, {
							Create("UIListLayout", {
								Padding = UDim.new(0, 8),
								HorizontalAlignment = Enum.HorizontalAlignment.Center,
								SortOrder = Enum.SortOrder.LayoutOrder
							}),
						})


						return {
							AddSlider = function(configs)
								configs = configs or {}
								configs.Name = configs.Name or "Slider"

								configs.Default = configs.Default or 50
								configs.Callback = configs.Callback or function() end

								configs.Description = configs.Description or false
								configs.DescriptionText = configs.DescriptionText or "Description"

								configs.Min = configs.Min or 0
								configs.Max = configs.Max or 100
								configs.Increment = configs.Increment or 1

								local Slider = {Value = configs.Default, Type = "Slider"}
								local Dragging = false
								
								configs.Flags = configs.Flags or tostring(#Library.Flags+1)
								Library.Flags[configs.Flags] = Slider 

								local entireHolding = Create("TextButton", {
									Name = configs.Name,
									Parent = elementsHolder,
									BackgroundColor3 = Color3.fromRGB(255, 255, 255),
									BackgroundTransparency = 1.000,
									BorderColor3 = Color3.fromRGB(0, 0, 0),
									BorderSizePixel = 0,
									Position = UDim2.new(0, 0, 0.519230783, 0),
									Size = UDim2.new(1, 0, 0, 40),
									AutoButtonColor = false,
									Font = Enum.Font.SourceSans,
									AutomaticSize = Enum.AutomaticSize.Y,
									Text = "",
									TextColor3 = Color3.fromRGB(0, 0, 0),
									TextSize = 14.000
								}, {
									Create("UIPadding", {
										PaddingBottom = UDim.new(0,4),
										PaddingLeft = UDim.new(0,10),
										PaddingRight = UDim.new(0,10),
										PaddingTop = UDim.new(0,4)
									}),
									Create("TextLabel", {
										Name = "name",
										BackgroundColor3 = Color3.fromRGB(255, 255, 255),
										BackgroundTransparency = 1.000,
										BorderColor3 = Color3.fromRGB(0, 0, 0),
										BorderSizePixel = 0,
										Position = UDim2.new(-0.0196560472, 8, 0, 0),
										Size = UDim2.new(0, 312, 0, 16),
										Font = Enum.Font.Gotham,
										Text = configs.Name,
										TextColor3 = Color3.fromRGB(234, 234, 234),
										TextSize = 14.000,
										TextXAlignment = Enum.TextXAlignment.Left
									}),
									Create("TextLabel", {
										Name = "description",
										BackgroundColor3 = Color3.fromRGB(255, 255, 255),
										BackgroundTransparency = 1.000,
										BorderColor3 = Color3.fromRGB(0, 0, 0),
										BorderSizePixel = 0,
										Position = UDim2.new(0, 0, 0, 38),
										Size = UDim2.new(1, 0, 0, 16),
										Font = Enum.Font.Gotham,
										Text = configs.DescriptionText,
										TextColor3 = Color3.fromRGB(154, 154, 154),
										TextSize = 14.000,
										TextWrapped = true,
										TextXAlignment = Enum.TextXAlignment.Left,
										Visible = configs.Description and true or false
									})
								})

								local ValueText = Create("TextLabel", {
									Name = "value",
									Parent = entireHolding,
									BackgroundColor3 = Color3.fromRGB(255, 255, 255),
									BackgroundTransparency = 1.000,
									BorderColor3 = Color3.fromRGB(0, 0, 0),
									BorderSizePixel = 0,
									Position = UDim2.new(0.754537523, 8, 0, 0),
									Size = UDim2.new(0, 90, 0, 16),
									Font = Enum.Font.Gotham,
									Text = Slider.Value,
									TextColor3 = Color3.fromRGB(234, 234, 234),
									TextSize = 14.000,
									TextXAlignment = Enum.TextXAlignment.Right
								})

								local SliderFrame = Create("Frame", {
									Parent = entireHolding,
									AnchorPoint = Vector2.new(0.5, 0),
									BackgroundColor3 = Color3.fromRGB(21, 21, 21),
									BorderColor3 = Color3.fromRGB(0, 0, 0),
									BorderSizePixel = 0,
									Position = UDim2.new(0.5, 0, 0, 26),
									Size = UDim2.new(1, 0, 0, 2),
								}, {
									Create("UICorner", {
										CornerRadius = UDim.new(0,2)	
									}),
									Create("UIStroke", {
										ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
										Color = Color3.fromRGB(29, 29, 29)
									})
								})

								local SliderProgress = Create("Frame", {
									Name = "slideindicator",
									Parent = SliderFrame,
									AnchorPoint = Vector2.new(0, 0.5),
									BackgroundColor3 = Color3.fromRGB(11, 123, 82),
									BorderColor3 = Color3.fromRGB(0, 0, 0),
									BorderSizePixel = 0,
									Position = UDim2.new(0, 0, 0.5, 0),
									Size = UDim2.new(0, 100, 1, 0)
								}, {	
									Create("UICorner", {
										CornerRadius = UDim.new(0,2)	
									}),
									Create("UIStroke", {
										ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
										Color = Color3.fromRGB(9, 144, 95)
									})
								})

								local SliderDot = Create("TextButton", {
									Name = "slidethumb",
									Parent = SliderFrame,
									AnchorPoint = Vector2.new(1, 0.5),
									BackgroundColor3 = Color3.fromRGB(11, 123, 82),
									BorderColor3 = Color3.fromRGB(0, 0, 0),
									BorderSizePixel = 0,
									Position = UDim2.new(1, 5, 0.5, 0),
									Size = UDim2.new(0, 10, 0, 10),
									Text = ""
								}, {	
									Create("UICorner", {
										CornerRadius = UDim.new(1,0)	
									}),
									Create("UIStroke", {
										ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
										Color = Color3.fromRGB(9, 144, 95)
									})
								})
								AddConnection(UserInputService.InputChanged, function(Input)
									if Dragging and Input.UserInputType == Enum.UserInputType.MouseMovement then 
										local SizeScale = math.clamp((Input.Position.X - SliderFrame.AbsolutePosition.X) / SliderFrame.AbsoluteSize.X, 0, 1)
										Slider:Set(configs.Min + ((configs.Max - configs.Min) * SizeScale)) 
									end
								end)

								AddConnection(SliderDot.InputBegan, function(Input)
									if Input.UserInputType == Enum.UserInputType.MouseButton1 then 
										Dragging = true;
									end 
								end)

								AddConnection(SliderDot.InputEnded, function(Input)
									if Input.UserInputType == Enum.UserInputType.MouseButton1 then 
										Dragging = false;
									end 
								end)

								function Slider:Set(Value)
									self.Value = math.clamp(Round(Value, configs.Increment), configs.Min, configs.Max)
									ValueText.Text = Library.Settings.Elements.ShowSliderMax and (tostring(self.Value).." / "..configs.Max) or tostring(self.Value)
									TweenService:Create(SliderDot,TweenInfo.new(.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),{Position = UDim2.new((self.Value - configs.Min) / (configs.Max - configs.Min), 5, SliderDot.Position.Y.Scale,SliderDot.Position.Y.Offset)}):Play()
									TweenService:Create(SliderProgress,TweenInfo.new(.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),{Size = UDim2.fromScale((self.Value - configs.Min) / (configs.Max - configs.Min), 1)}):Play()
									return configs.Callback(self.Value)
								end


								Slider:Set(Slider.Value)
								return Slider
							end,
							
							AddToggle = function(configs)
								configs = configs or {}
								configs.Name = configs.Name or "Toggle"

								configs.Default = configs.Default or false
								configs.Callback = configs.Callback or function() end

								configs.Description = configs.Description or false
								configs.DescriptionText = configs.DescriptionText or "Description"
								
								local toggle = {Value = configs.Default, Type = "Toggle"}
								
								local Toggle = Create("TextButton", {
									Name = configs.Name,
									AutoButtonColor = false,
									AutomaticSize = Enum.AutomaticSize.Y,
									BackgroundColor3 = Color3.fromRGB(255, 255, 255),
									BackgroundTransparency = 1,
									BorderColor3 = Color3.fromRGB(0, 0, 0),
									BorderSizePixel = 0,
									FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
									Position = UDim2.fromScale(0, 0.519),
									Size = UDim2.fromScale(1, 0),
									Text = "",
									TextColor3 = Color3.fromRGB(0, 0, 0),
									TextSize = 14,
									Parent = elementsHolder
								}, {
									Create("UIPadding", {
										Name = "UIPadding",
										PaddingBottom = UDim.new(0, 4),
										PaddingLeft = UDim.new(0, 10),
										PaddingRight = UDim.new(0, 10),
										PaddingTop = UDim.new(0, 4)
									}),

									Create("TextLabel", {
										Name = "name",
										BackgroundColor3 = Color3.fromRGB(255, 255, 255),
										BackgroundTransparency = 1,
										BorderColor3 = Color3.fromRGB(0, 0, 0),
										BorderSizePixel = 0,
										FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
										Position = UDim2.new(0.0393, 8, 0, 0),
										Size = UDim2.fromOffset(381, 16),
										Text = configs.Name,
										TextColor3 = Color3.fromRGB(234, 234, 234),
										TextSize = 14,
										TextTruncate = Enum.TextTruncate.AtEnd,
										TextXAlignment = Enum.TextXAlignment.Left
									}),

									Create("TextLabel", {
										Name = "description",
										AutomaticSize = Enum.AutomaticSize.Y,
										BackgroundColor3 = Color3.fromRGB(255, 255, 255),
										BackgroundTransparency = 1,
										BorderColor3 = Color3.fromRGB(0, 0, 0),
										BorderSizePixel = 0,
										FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
										Position = UDim2.fromOffset(0, 23),
										RichText = true,
										Size = UDim2.new(1, 0, 0, 16),
										Text = configs.DescriptionText,
										TextColor3 = Color3.fromRGB(154, 154, 154),
										TextSize = 14,
										TextWrapped = true,
										TextXAlignment = Enum.TextXAlignment.Left,
										Visible = configs.Description and true or false
									}),
									Create("Frame", {
										Name = "ToggleStatus",
										BackgroundColor3 = Color3.fromRGB(11, 123, 82),
										BorderColor3 = Color3.fromRGB(0, 0, 0),
										BorderSizePixel = 0,
										Size = UDim2.fromOffset(16, 16)
									},{
										Create("UICorner", {
											CornerRadius = UDim.new(0, 2)	
										}),
										Create("ImageLabel", {
											Name = "Toggle Icon",
											AnchorPoint = Vector2.new(0.5, 0.5),
											BackgroundColor3 = Color3.fromRGB(255, 255, 255),
											BackgroundTransparency = 1,
											BorderColor3 = Color3.fromRGB(0, 0, 0),
											BorderSizePixel = 0,
											Image = "http://www.roblox.com/asset/?id=6031094667",
											ImageColor3 = Color3.fromRGB(17, 17, 17),
											Position = UDim2.fromScale(0.5, 0.5),
											Size = UDim2.fromOffset(12, 12)
										}),
										Create("UIStroke", {
											ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
											Color = Color3.fromRGB(36, 36, 36)
											})

										})
									})

									AddConnection(Toggle.MouseButton1Click, function()
										toggle:Set(not toggle.Value)
									end)

									function toggle:Set(val)
										self.Value = val
										TweenService:Create(Toggle.ToggleStatus, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundTransparency = val and 0 or 1}):Play()
										return configs.Callback(self.Value)
									end

									configs.Flags = configs.Flags or tostring(#Library.Flags+1)
									Library.Flags[configs.Flags] = toggle 
									
									toggle:Set(toggle.Value)
									
									
									return toggle
								end,
								
								AddTextbox = function(configs)
									configs = configs or {}
									configs.Name = configs.Name or "Textbox"
									configs.Default = configs.Default or "Text here"	
									configs.Callback = configs.Callback or function() end
									configs.Description = configs.Description or false
									configs.Dissapear = configs.Dissapear or false 
									configs.DescriptionText = configs.DescriptionText or "description"
									
									local textbox = {Text = false}
									configs.Flags = configs.Flags or tostring(#Library.Flags+1)
									Library.Flags[configs.Flags] = textbox 
									
									local Textbox = Create("TextButton", {
										Name = configs.Name,
										Parent = elementsHolder,
										BackgroundColor3 = Color3.fromRGB(255, 255, 255),
										BackgroundTransparency = 1,
										BorderColor3 = Color3.fromRGB(0, 0, 0),
										BorderSizePixel = 0,
										Position = UDim2.new(0, 0, 0.519230783, 0),
										Size = UDim2.new(1, 0, 0, 40),
										AutoButtonColor = false,
										Font = Enum.Font.SourceSans,
										Text = "",
										TextColor3 = Color3.fromRGB(0, 0, 0),
										TextSize = 14
									}, {
										Create("TextLabel", {
											Name = "name",
											BackgroundColor3 = Color3.fromRGB(255, 255, 255),
											BackgroundTransparency = 1,
											BorderColor3 = Color3.fromRGB(0, 0, 0),
											BorderSizePixel = 0,
											Position = UDim2.new(-0.0196560472, 8, 0, 0),
											Size = UDim2.new(0, 312, 0, 16),
											Font = Enum.Font.Gotham,
											Text = configs.Name,
											TextColor3 = Color3.fromRGB(234, 234, 234),
											TextSize = 14,
											TextXAlignment = Enum.TextXAlignment.Left
										}),
										Create("UIPadding", {
											PaddingBottom = UDim.new(0, 4),
											PaddingLeft = UDim.new(0, 10),
											PaddingRight = UDim.new(0, 10),
											PaddingTop = UDim.new(0, 4)
										}),
										Create("TextLabel", {
											Name = "description",
											BackgroundColor3 = Color3.fromRGB(255, 255, 255),
											BackgroundTransparency = 1,
											BorderColor3 = Color3.fromRGB(0, 0, 0),
											BorderSizePixel = 0,
											Position = UDim2.new(0, 0, 0, 16),
											Size = UDim2.new(0.468982637, 0, 0, 16),
											Font = Enum.Font.Gotham,
											Text = configs.DescriptionText,
											TextColor3 = Color3.fromRGB(154, 154, 154),
											TextSize = 14,
											TextWrapped = true,
											TextXAlignment = Enum.TextXAlignment.Left,
											Visible = configs.Description
										}),
										Create("TextBox", {
											Name = "Typingbox",
											Active = true,
											AnchorPoint = Vector2.new(1, 0.5),
											BackgroundColor3 = Color3.fromRGB(21, 21, 21),
											BorderColor3 = Color3.fromRGB(0, 0, 0),
											BorderSizePixel = 0,
											Position = UDim2.new(1, 0, 0.5, 0),
											Size = UDim2.new(0, 0, 0, 25),
											Font = Enum.Font.Gotham,
											Text = configs.Default,
											TextColor3 = Color3.fromRGB(154, 154, 154),
											TextSize = 14,
											TextWrapped = true,
											TextXAlignment = Enum.TextXAlignment.Right,
											AutomaticSize = Enum.AutomaticSize.X,
											ClearTextOnFocus = configs.Dissapear,
											PlaceholderText = "empty",
											PlaceholderColor3 = Color3.fromRGB(130,130,130)

										}, {
											Create("UIStroke", {
												ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
												Color = Color3.fromRGB(36, 36, 36)
											}),
											Create("UICorner", {
												CornerRadius = UDim.new(0, 2)	
											}),
											Create("UIPadding", {
												PaddingLeft = UDim.new(0,10),
												PaddingRight = UDim.new(0,10)
											})
										})
									})
									
									AddConnection(Textbox.MouseButton1Click, function()
										Textbox:FindFirstChild("Typingbox", true):CaptureFocus()
									end)
									
									AddConnection(Textbox:FindFirstChild("Typingbox", true).Focused, function()
										TweenService:Create(Textbox:FindFirstChild("Typingbox", true), TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(234, 234, 234)}):Play()
									end)
									
									AddConnection(Textbox:FindFirstChild("Typingbox", true).FocusLost, function()
										configs.Callback(Textbox:FindFirstChild("Typingbox", true).Text)
										Textbox:FindFirstChild("Typingbox", true).Text = configs.Dissapear and "" or Textbox:FindFirstChild("Typingbox", true).Text
										TweenService:Create(Textbox:FindFirstChild("Typingbox", true), TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextColor3 = Color3.fromRGB(154, 154, 154)}):Play()
									end)
									
									function textbox:Set(text)
										configs.Callback(text)
										Textbox:FindFirstChild("Typingbox", true).Text = text
									end

								end,

								Addbind = function(configs)
									configs = configs or {}
									configs.Name = configs.Name or "Keybind"
									configs.Default = configs.Default or Enum.KeyCode.E
									configs.Callback = configs.Callback or function() end
									configs.Hold = configs.Hold or false
									configs.Description = configs.Description or false
									configs.DescriptionText = configs.DescriptionText or "description"

									local Bind = {Value = false, Binding = false, Type = "Bind"}
									local Holding = false
									
									configs.Flags = configs.Flags or tostring(#Library.Flags+1)
									Library.Flags[configs.Flags] = Bind 

									local Keybind = Create("TextButton", {
										Name = configs.Name,
										Parent = elementsHolder,
										BackgroundColor3 = Color3.fromRGB(255, 255, 255),
										BackgroundTransparency = 1,
										BorderColor3 = Color3.fromRGB(0, 0, 0),
										BorderSizePixel = 0,
										Position = UDim2.new(0, 0, 0.519230783, 0),
										Size = UDim2.new(1, 0, 0, 40),
										AutoButtonColor = false,
										Font = Enum.Font.SourceSans,
										Text = "",
										TextColor3 = Color3.fromRGB(0, 0, 0),
										TextSize = 14
									}, {
										Create("TextLabel", {
											Name = "name",
											BackgroundColor3 = Color3.fromRGB(255, 255, 255),
											BackgroundTransparency = 1,
											BorderColor3 = Color3.fromRGB(0, 0, 0),
											BorderSizePixel = 0,
											Position = UDim2.new(-0.0196560472, 8, 0, 0),
											Size = UDim2.new(0, 312, 0, 16),
											Font = Enum.Font.Gotham,
											Text = configs.Name,
											TextColor3 = Color3.fromRGB(234, 234, 234),
											TextSize = 14,
											TextXAlignment = Enum.TextXAlignment.Left
										}),
										Create("UIPadding", {
											PaddingBottom = UDim.new(0, 4),
											PaddingLeft = UDim.new(0, 10),
											PaddingRight = UDim.new(0, 10),
											PaddingTop = UDim.new(0, 4)
										}),
										Create("TextLabel", {
											Name = "description",
											BackgroundColor3 = Color3.fromRGB(255, 255, 255),
											BackgroundTransparency = 1,
											BorderColor3 = Color3.fromRGB(0, 0, 0),
											BorderSizePixel = 0,
											Position = UDim2.new(0, 0, 0, 16),
											Size = UDim2.new(0.468982637, 0, 0, 16),
											Font = Enum.Font.Gotham,
											Text = configs.DescriptionText,
											TextColor3 = Color3.fromRGB(154, 154, 154),
											TextSize = 14,
											TextWrapped = true,
											TextXAlignment = Enum.TextXAlignment.Left,
											Visible = configs.Description
										}),
										Create("TextLabel", {
											Name = "keybind_selected",
											Active = true,
											AnchorPoint = Vector2.new(1, 0.5),
											BackgroundColor3 = Color3.fromRGB(21, 21, 21),
											BorderColor3 = Color3.fromRGB(0, 0, 0),
											BorderSizePixel = 0,
											Position = UDim2.new(1, 0, 0.5, 0),
											Size = UDim2.new(0, 0, 0, 25),
											Font = Enum.Font.Gotham,
											Text = "",
											TextColor3 = Color3.fromRGB(154, 154, 154),
											TextSize = 14,
											TextWrapped = true,
											TextXAlignment = Enum.TextXAlignment.Right,
											AutomaticSize = Enum.AutomaticSize.X,

										}, {
											Create("UIStroke", {
												ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
												Color = Color3.fromRGB(36, 36, 36)
											}),
											Create("UICorner", {
												CornerRadius = UDim.new(0, 2)	
											}),
											Create("UIPadding", {
												PaddingLeft = UDim.new(0,10),
												PaddingRight = UDim.new(0,10)
											})
										})
									})

									AddConnection(Keybind.InputEnded, function(Input)
										if Input.UserInputType == Enum.UserInputType.MouseButton1 then
											if Bind.Binding then return end
											Bind.Binding = true
											Keybind.keybind_selected.Text = "..."
										end
									end)

									AddConnection(UserInputService.InputBegan, function(Input)
										if UserInputService:GetFocusedTextBox() then return end
										if (Input.KeyCode.Name == Bind.Value or Input.UserInputType.Name == Bind.Value) and not Bind.Binding then
											if configs.Hold then
												Holding = true
												configs.Callback(Holding)
											else
												configs.Callback()
											end
										elseif Bind.Binding then
											local Key
											pcall(function()
												if not CheckKey(BlacklistedKeys, Input.KeyCode) then
													Key = Input.KeyCode
												end
											end)
											pcall(function()
												if CheckKey(WhitelistedMouse, Input.UserInputType) and not Key then
													Key = Input.UserInputType
												end
											end)
											Key = Key or Bind.Value
											Bind:Set(Key)
										end
									end)

									AddConnection(UserInputService.InputEnded, function(Input)
										if Input.KeyCode.Name == Bind.Value or Input.UserInputType.Name == Bind.Value then
											if configs.Hold and Holding then
												Holding = false
												configs.Callback(Holding)
											end
										end
									end)


									function Bind:Set(Key)
										Bind.Binding = false
										Bind.Value = Key or Bind.Value
										Bind.Value = Bind.Value.Name or Bind.Value
										Keybind.keybind_selected.Text = Bind.Value
									end

									Bind:Set(configs.Default)
									return Bind
								end,
	AddDropdown = function(configs)
		configs.Name = configs.Name or "Dropdown"
		configs.Callback = configs.Callback or function() end
		configs.Options = configs.Options or {}
		configs.Flag = configs.Flag or nil
		configs.Description = configs.Description or false
		configs.DescriptionText = configs.DescriptionText or "description"
		configs.Default = configs.Default or configs.Options[1] or "..."

		local Dropdown = {
			Toggled = false,
			Value = configs.Default,
			Type = "Dropdown",
			Buttons = {},
			Options = configs.Options
		}

		if not table.find(configs.Options, Dropdown.Value) then
			Dropdown.Value = configs.Options[1] or "..."
		end

		local DropdownContainer = Create("TextButton", {
			Parent = elementsHolder,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 40),
			AutoButtonColor = false,
			Text = "",
			Font = Enum.Font.SourceSans,
			TextSize = 14,
			Name = configs.Name,
			AutomaticSize = Enum.AutomaticSize.Y,
		}, {
			Create("UIPadding", {
				PaddingBottom = UDim.new(0, 4),
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
				PaddingTop = UDim.new(0, 4)
			}),
			Create("TextLabel", {
				Name = "name",
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 8, 0, 0),
				Size = UDim2.new(0, 312, 0, 16),
				Font = Enum.Font.Gotham,
				Text = configs.Name,
				TextColor3 = Color3.fromRGB(234, 234, 234),
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left
			}),
			Create("TextLabel", {
				Name = "description",
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 0, 0, 16),
				Size = UDim2.new(1, 0, 0, 16),
				Font = Enum.Font.Gotham,
				Text = configs.DescriptionText,
				TextColor3 = Color3.fromRGB(154, 154, 154),
				TextSize = 14,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left
			}),
			Create("TextButton", {
				Name = "Dropdown button",
				BackgroundColor3 = Color3.fromRGB(21, 21, 21),
				ClipsDescendants = true,
				Position = UDim2.new(0.499, 8, 0, 0),
				Size = UDim2.new(0, 192, 0, 32),
				AutoButtonColor = false,
				Font = Enum.Font.SourceSans,
				Text = "",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 14
			}, {
				Create("UICorner", {
					CornerRadius = UDim.new(0, 2)
				}),
				Create("UIStroke", {
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Color = Color3.fromRGB(36, 36, 36),
				}),
				Create("TextLabel", {
					Name = "SelectedText",
					BackgroundTransparency = 1,
					Size = UDim2.new(1, -10, 0, 32),
					Position = UDim2.new(0, 5, 0, 0),
					Font = Enum.Font.Gotham,
					Text = Dropdown.Value,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 14,
					TextXAlignment = Enum.TextXAlignment.Left
				}),
				Create("Frame", {
					Name = "Dropdownseperator",
					BackgroundColor3 = Color3.fromRGB(36, 36, 36),
					Size = UDim2.new(1, 0, 0, 1),
					Position = UDim2.new(0, 0, 0, 32)
				}),
				Create("TextButton", {
					Name = "ClickDetector",
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 32),
					TextTransparency = 1
				}),
				Create("Frame", {
					Name = "OptionsHolder",
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 0, 0, 33),
					Size = UDim2.new(1, 0, 0, #configs.Options * 24),
					Visible = false
				}, {
					Create("UIListLayout", {
						SortOrder = Enum.SortOrder.LayoutOrder
					})
				})
			})
		})

		local DropdownButton = DropdownContainer:FindFirstChild("Dropdown button", true)
		local OptionsHolder = DropdownButton:FindFirstChild("OptionsHolder")
		local SelectedText = DropdownButton:FindFirstChild("SelectedText")

		for _, option in ipairs(configs.Options) do
			local OptionBtn = Create("TextButton", {
				Parent = OptionsHolder,
				BackgroundColor3 = Color3.fromRGB(30, 30, 30),
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 24),
				Font = Enum.Font.Gotham,
				Text = option,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 14,
				AutoButtonColor = true
			}, {
				Create("UICorner", {
					CornerRadius = UDim.new(0, 2)
				})
			})

			OptionBtn.MouseButton1Click:Connect(function()
				Dropdown.Value = option
				SelectedText.Text = option
				Dropdown.Toggled = false
				OptionsHolder.Visible = false
				DropdownButton.Size = UDim2.new(0, 192, 0, 32)
				configs.Callback(option)
			end)

			table.insert(Dropdown.Buttons, OptionBtn)
		end

		AddConnection(DropdownButton.ClickDetector.MouseButton1Click, function()
			Dropdown.Toggled = not Dropdown.Toggled
			OptionsHolder.Visible = Dropdown.Toggled
			local expandedHeight = 32 + (#configs.Options * 24)
			TweenService:Create(DropdownButton, TweenInfo.new(0.1), {
				Size = UDim2.new(0, 192, 0, Dropdown.Toggled and expandedHeight or 32)
			}):Play()
		end)

		function Dropdown:Set(Value)
			if table.find(configs.Options, Value) then
				self.Value = Value
				SelectedText.Text = Value
				configs.Callback(Value)
			end
		end

		return Dropdown
	end,

								AddButton = function(configs)
									configs.Name = configs.Name or "Button"
									configs.Callback = configs.Callback or function() end 

									configs.Accented = configs.Accented or false
									
	local Button;

	if configs.Accented then
		Button = Create("TextButton", {
			Name = configs.Name,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(11, 123, 82),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
			Size = UDim2.new(0.9, 0, 0, 25),
			Text = "",
			TextColor3 = Color3.fromRGB(0, 0, 0),
			TextSize = 14,
			Parent = elementsHolder,
			AutoButtonColor = true
		}, {
			Create("TextLabel", {
				Name = "name",
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(381, 16),
				Text = configs.Name,
				TextColor3 = Color3.fromRGB(234, 234, 234),
				TextSize = 14,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = Button
			}),
			Create("UICorner", {
				CornerRadius = UDim.new(0, 2)	
			}),
			Create("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = Color3.fromRGB(14, 157, 105),
			})
		})
	else
		Button = Create("TextButton", {
			Name = configs.Name,
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(21, 21, 21),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
			Size = UDim2.new(0.9, 0, 0, 25),
			Text = "",
			TextColor3 = Color3.fromRGB(0, 0, 0),
			TextSize = 14,
			Parent = elementsHolder,
			AutoButtonColor = true
		}, {
			Create("TextLabel", {
				Name = "name",
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json"),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromOffset(381, 16),
				Text = configs.Name,
				TextColor3 = Color3.fromRGB(234, 234, 234),
				TextSize = 14,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = Button
			}),
			Create("UICorner", {
				CornerRadius = UDim.new(0, 2)	
			}),
			Create("UIStroke", {
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				Color = Color3.fromRGB(36, 36, 36),
			})
		})
	end

	print(configs.Name)
	buttonsbfsa[configs.Name] = Button



									AddConnection(Button.MouseButton1Click, function()
										configs.Callback()
									end)
									return Button
								end,
							}
						end,
					}
				end
			}
		end
		local function HexToColor3(hex)
			hex = hex:gsub("#","")
			return Color3.fromRGB(tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6)))
		end
		
		_G.NotificationActive = _G.NotificationActive or {}
		local ActiveNotifications = _G.NotificationActive
		local Notification = {}
		local NotificationSpacing = 10
		local BottomOffset = 20
		local NotificationHeight = 75
		
		local NotificationFolder
		do
			local existingGui = CoreGui:FindFirstChild("NotificationSystem")
			if existingGui and existingGui:FindFirstChild("Notifications") then
				NotificationFolder = existingGui.Notifications
			end
		end
		
		local function CreateNotificationUI()
			local ScreenGui = Instance.new("ScreenGui")
			ScreenGui.Name = "NotificationSystem"
			ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
			ScreenGui.ResetOnSpawn = false
			ScreenGui.DisplayOrder = 10000
			local success = pcall(function() ScreenGui.Parent = CoreGui end)
			if not success then
				ScreenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
			end
			local NotificationsFolder = Instance.new("Folder")
			NotificationsFolder.Name = "Notifications"
			NotificationsFolder.Parent = ScreenGui
			return NotificationsFolder
		end
		
		if not NotificationFolder then
			NotificationFolder = CreateNotificationUI()
		end
		
		local LucideLoaded = false
		local LucideIcons = nil
		local LucideIconsUrl = "https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/icons.lua"
		
		local function safeHttpGet(url, retries)
			retries = retries or 3
			local success, result
			for i = 1, retries do
				success, result = pcall(function() return game:HttpGet(url) end)
				if success then return result elseif i < retries then task.wait(0.5) end
			end
			return nil
		end
		
		local function LoadLucideIcons()
			if LucideLoaded then return LucideIcons end
			local iconData = safeHttpGet(LucideIconsUrl)
			if not iconData then warn("Failed to load Lucide icons after multiple attempts.") return nil end
			local success, icons = pcall(function() return loadstring(iconData)() end)
			if success and icons then
				LucideLoaded = true
				LucideIcons = icons
				return icons
			else
				warn("Failed to process Lucide icons:", icons)
				return nil
			end
		end
		
		local function GetLucideIcon(iconName)
			if not LucideIcons then
				LucideIcons = LoadLucideIcons()
				if not LucideIcons then return nil end
			end
			iconName = string.lower(string.match(iconName, "^%s*(.-)%s*$"))
			local iconSet = LucideIcons["48px"]
			if not iconSet then return nil end
			local iconData = iconSet[iconName]
			if not iconData then return nil end
			return { id = iconData[1], imageRectSize = Vector2.new(iconData[2][1], iconData[2][2]), imageRectOffset = Vector2.new(iconData[3][1], iconData[3][2]) }
		end
		
		local function UpdateNotificationPositions()
			local total = #ActiveNotifications
			for index, notification in ipairs(ActiveNotifications) do
				if notification.Instance and notification.Instance.Parent then
					local reverseIndex = total - index
					local yOffset = BottomOffset + reverseIndex * (NotificationHeight + NotificationSpacing)
					local targetPos = UDim2.new(1, -20, 1, -yOffset)
					TweenService:Create(notification.Instance, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = targetPos }):Play()
				end
			end
		end
		
		local function RemoveNotification(notification)
			for i, activeNotif in ipairs(ActiveNotifications) do
				if activeNotif == notification then
					table.remove(ActiveNotifications, i)
					break
				end
			end
			UpdateNotificationPositions()
		end
		
		function Notification.notify(options)
			options = options or {}
			local title = options.Title or "Notification"
			local content = options.Content or "This is a notification"
			local duration = options.Duration or 3
			local icon = options.Icon or "bell"
			local bgColor = options.Color or Color3.fromRGB(25, 25, 35)
			local textColor = options.TextColor or Color3.fromRGB(255, 255, 255)
			local accentColor = options.AccentColor or Color3.fromRGB(114, 137, 218)
			local presetIcons = {
				["Bell"] = { icon = "bell", color = accentColor },
				["Info"] = { icon = "info", color = Color3.fromRGB(89, 175, 255) },
				["Warning"] = { icon = "alert-triangle", color = Color3.fromRGB(255, 184, 48) },
				["Success"] = { icon = "check-circle", color = Color3.fromRGB(72, 207, 128) },
				["Error"] = { icon = "x-circle", color = Color3.fromRGB(236, 88, 96) }
			}
			local lucideIconName = icon
			local iconColor = accentColor
			if presetIcons[icon] then
				lucideIconName = presetIcons[icon].icon
				iconColor = presetIcons[icon].color
			else
				lucideIconName = icon:lower()
			end
			if options.IconTheme then
				iconColor = HexToColor3(options.IconTheme)
			end
			local NotifFrame = Instance.new("Frame")
			NotifFrame.Name = "Notification_" .. HttpService:GenerateGUID(false)
			NotifFrame.Size = UDim2.new(0, 300, 0, NotificationHeight)
			NotifFrame.AnchorPoint = Vector2.new(1, 1)
			NotifFrame.BackgroundColor3 = bgColor
			NotifFrame.BackgroundTransparency = 1
			NotifFrame.BorderSizePixel = 0
			local startingPos = UDim2.new(1, 300, 1, -BottomOffset)
			NotifFrame.Position = startingPos
			NotifFrame.Parent = NotificationFolder
			local borderFrame = Instance.new("Frame")
			borderFrame.Name = "BorderGlow"
			borderFrame.Size = UDim2.new(1, 0, 1, 0)
			borderFrame.BackgroundTransparency = 1
			borderFrame.BorderSizePixel = 0
			borderFrame.Parent = NotifFrame
			local borderStroke = Instance.new("UIStroke")
			borderStroke.Thickness = 1
			borderStroke.Color = Color3.fromRGB(80, 80, 100)
			borderStroke.Transparency = 1
			borderStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			borderStroke.Parent = borderFrame
			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(0, 8)
			corner.Parent = NotifFrame
			local borderCorner = Instance.new("UICorner")
			borderCorner.CornerRadius = UDim.new(0, 8)
			borderCorner.Parent = borderFrame
			local Shadow = Instance.new("ImageLabel")
			Shadow.Name = "Shadow"
			Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
			Shadow.BackgroundTransparency = 1
			Shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
			Shadow.Size = UDim2.new(1, 40, 1, 40)
			Shadow.ZIndex = -1
			Shadow.Image = "rbxassetid://6014261993"
			Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
			Shadow.ImageTransparency = 1
			Shadow.ScaleType = Enum.ScaleType.Slice
			Shadow.SliceCenter = Rect.new(49, 49, 450, 450)
			Shadow.Parent = NotifFrame
			local IconContainer = Instance.new("Frame")
			IconContainer.Name = "IconContainer"
			IconContainer.Size = UDim2.new(0, 36, 0, 36)
			IconContainer.Position = UDim2.new(0, 15, 0.5, -18)
			IconContainer.BackgroundColor3 = iconColor
			IconContainer.BackgroundTransparency = 0.8
			IconContainer.Parent = NotifFrame
			local iconCorner = Instance.new("UICorner")
			iconCorner.CornerRadius = UDim.new(1, 0)
			iconCorner.Parent = IconContainer
			local IconImage = Instance.new("ImageLabel")
			IconImage.Name = "LucideIcon"
			IconImage.Size = UDim2.new(0, 20, 0, 20)
			IconImage.Position = UDim2.new(0.5, -10, 0.5, -10)
			IconImage.BackgroundTransparency = 1
			IconImage.ImageColor3 = iconColor
			IconImage.Parent = IconContainer
			local iconData = GetLucideIcon(lucideIconName)
			if iconData then
				IconImage.Image = "rbxassetid://" .. iconData.id
				IconImage.ImageRectSize = iconData.imageRectSize
				IconImage.ImageRectOffset = iconData.imageRectOffset
			else
				local fallbackIconData = GetLucideIcon("bell")
				if fallbackIconData then
					IconImage.Image = "rbxassetid://" .. fallbackIconData.id
					IconImage.ImageRectSize = fallbackIconData.imageRectSize
					IconImage.ImageRectOffset = fallbackIconData.imageRectOffset
					warn("Lucide icon not found: " .. lucideIconName .. ". Using bell icon as fallback.")
				else
					IconImage.Image = "rbxassetid://6031071053"
					warn("Lucide icons not loaded. Using built-in fallback icon.")
				end
			end
			local TitleLabel = Instance.new("TextLabel")
			TitleLabel.Name = "Title"
			TitleLabel.Size = UDim2.new(0, 220, 0, 20)
			TitleLabel.Position = UDim2.new(0, 60, 0, 15)
			TitleLabel.BackgroundTransparency = 1
			TitleLabel.Text = title
			TitleLabel.TextColor3 = textColor
			TitleLabel.TextSize = 16
			TitleLabel.Font = Enum.Font.GothamBold
			TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
			TitleLabel.Parent = NotifFrame
			local ContentLabel = Instance.new("TextLabel")
			ContentLabel.Name = "Content"
			ContentLabel.Size = UDim2.new(0, 220, 0, 30)
			ContentLabel.Position = UDim2.new(0, 60, 0, 35)
			ContentLabel.BackgroundTransparency = 1
			ContentLabel.Text = content
			ContentLabel.TextColor3 = textColor
			ContentLabel.TextTransparency = 0.3
			ContentLabel.TextSize = 14
			ContentLabel.Font = Enum.Font.Gotham
			ContentLabel.TextXAlignment = Enum.TextXAlignment.Left
			ContentLabel.TextYAlignment = Enum.TextYAlignment.Top
			ContentLabel.TextWrapped = true
			ContentLabel.Parent = NotifFrame
			local ProgressBar = Instance.new("Frame")
			ProgressBar.Name = "ProgressBar"
			ProgressBar.Size = UDim2.new(1, 0, 0, 3)
			ProgressBar.Position = UDim2.new(0, 0, 1, -3)
			ProgressBar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
			ProgressBar.BackgroundTransparency = 0.5
			ProgressBar.BorderSizePixel = 0
			ProgressBar.Parent = NotifFrame
			local progressCorner = Instance.new("UICorner")
			progressCorner.CornerRadius = UDim.new(0, 3)
			progressCorner.Parent = ProgressBar
			local ProgressFill = Instance.new("Frame")
			ProgressFill.Name = "Fill"
			ProgressFill.Size = UDim2.new(1, 0, 1, 0)
			ProgressFill.BackgroundColor3 = iconColor
			ProgressFill.BorderSizePixel = 0
			ProgressFill.Parent = ProgressBar
			local fillCorner = Instance.new("UICorner")
			fillCorner.CornerRadius = UDim.new(0, 3)
			fillCorner.Parent = ProgressFill
			local CloseButton = Instance.new("ImageButton")
			CloseButton.Name = "CloseButton"
			CloseButton.Size = UDim2.new(0, 20, 0, 20)
			CloseButton.Position = UDim2.new(1, -25, 0, 15)
			CloseButton.BackgroundTransparency = 1
			CloseButton.Parent = NotifFrame
			local closeIconData = GetLucideIcon("x")
			if closeIconData then
				CloseButton.Image = "rbxassetid://" .. closeIconData.id
				CloseButton.ImageRectSize = closeIconData.imageRectSize
				CloseButton.ImageRectOffset = closeIconData.imageRectOffset
			else
				CloseButton.Image = "rbxassetid://6035047409"
			end
			CloseButton.ImageColor3 = Color3.fromRGB(220, 220, 220)
			CloseButton.ImageTransparency = 0.4
			local notificationInfo = { Instance = NotifFrame, CreatedAt = os.clock(), Duration = duration }
			table.insert(ActiveNotifications, notificationInfo)
			task.defer(UpdateNotificationPositions)
			local newIndex = #ActiveNotifications
			local targetY = BottomOffset + (newIndex - 1) * (NotificationHeight + NotificationSpacing)
			local targetPos = UDim2.new(1, -20, 1, -targetY)
			TweenService:Create(NotifFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = targetPos, BackgroundTransparency = 0 }):Play()
			TweenService:Create(Shadow, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { ImageTransparency = 0.5 }):Play()
			TweenService:Create(borderStroke, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Transparency = 0.7 }):Play()
			local progressTween = TweenService:Create(ProgressFill, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Size = UDim2.new(0, 0, 1, 0) })
			progressTween:Play()
			local function slideOut()
				RemoveNotification(notificationInfo)
				progressTween:Cancel()
				local fadeOut = TweenService:Create(NotifFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Position = UDim2.new(1, 300, 1, NotifFrame.Position.Y.Offset), BackgroundTransparency = 1 })
				local fadeShadow = TweenService:Create(Shadow, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { ImageTransparency = 1 })
				local fadeBorder = TweenService:Create(borderStroke, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Transparency = 1 })
				fadeOut:Play()
				fadeShadow:Play()
				fadeBorder:Play()
				fadeOut.Completed:Connect(function() NotifFrame:Destroy() end)
			end
			CloseButton.MouseButton1Click:Connect(slideOut)
			NotifFrame.MouseEnter:Connect(function()
				progressTween:Pause()
				TweenService:Create(NotifFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quint), { BackgroundColor3 = Color3.fromRGB(math.min(bgColor.R * 255 + 15,255)/255, math.min(bgColor.G * 255 + 15,255)/255, math.min(bgColor.B * 255 + 15,255)/255) }):Play()
			end)
			NotifFrame.MouseLeave:Connect(function()
				progressTween:Play()
				TweenService:Create(NotifFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quint), { BackgroundColor3 = bgColor }):Play()
			end)
			CloseButton.MouseEnter:Connect(function()
				TweenService:Create(CloseButton, TweenInfo.new(0.2, Enum.EasingStyle.Quint), { ImageColor3 = Color3.fromRGB(255,100,100), ImageTransparency = 0 }):Play()
			end)
			CloseButton.MouseLeave:Connect(function()
				TweenService:Create(CloseButton, TweenInfo.new(0.2, Enum.EasingStyle.Quint), { ImageColor3 = Color3.fromRGB(220,220,220), ImageTransparency = 0.4 }):Play()
			end)
			task.delay(duration, slideOut)
			return NotifFrame
		end
		
		_G.NotificationActive = ActiveNotifications
