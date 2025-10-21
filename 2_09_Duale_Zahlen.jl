### A Pluto.jl notebook ###
# v0.20.19

using Markdown
using InteractiveUtils

# ╔═╡ f05a5972-58b1-4788-a0a8-24966d6714da
begin
	using PlutoUI
	using PlutoUI: Slider
end

# ╔═╡ 02ed8724-fbe6-4cdd-bab6-9f7ccfed8380
using BenchmarkTools

# ╔═╡ 72f1a9ed-3047-4ab9-b038-10c76984c540
using Enzyme

# ╔═╡ e6c64c80-773b-11ef-2379-bf6609137e69
md"""
# 2.9 Duale Zahlen und algorithmisches/automatisches Differenzieren

Algorithmisches/automatisches Differenzieren (AD) ist essentieller
Bestandteil vieler Anwendungen im maschinellen Lernen (deep learning).
Hier erklären wir kurz die grundlegenden Ideen von *forward-mode* AD und den
Zusammenhang mit dualen Zahlen.
"""

# ╔═╡ cd57529b-64a3-43cd-8dbf-445583c8edcc
md"""
## Forward-mode AD für Skalare

Es gibt das Sprichwort

> Ableiten ist ein Handwerk, Integrieren eine Kunst

Wir betrachten hier zum Glück nur automatisches/algorithmisches Differenzieren.
Also müssen wir nur die grundlegenden Rechenregel der Differentialrechnung
implementieren - die Produkt- und Kettenregel etc. Vorher betrachten wir jedoch
ein Beispiel.
"""

# ╔═╡ ee241f76-b1d9-4c00-9b53-020a1ba012dd
md"""
Wir können die Ableitung mithilfe der Kettenregel berechnen.
"""

# ╔═╡ 127944b9-b3eb-4df8-acc3-36d9958218ca
md"""
Wir können die Funktion auch als einen Graphen (*computational graph*) betrachten,
indem wir die Ausführung in einzelne Schritte zerlegen.
"""

# ╔═╡ a89b42c6-913e-4970-bd9e-8f163a4b96d8
md"""
Um die Ableitung zu berechnen können wir jetzt nacheinander die Kettenregel anwenden.
"""

# ╔═╡ 9777384f-dc51-4d6b-b55f-87b5fd2c5be7
md"""
Das würden wir jetzt gerne automatisieren! Dazu verwenden wir sogenannte
[duale Zahlen](https://en.wikipedia.org/wiki/Dual_number#Differentiation).
Diese haben einen Wert (`value`) und eine Ableitung (*derivative*, `deriv` --
der ε-Teil von oben). Formal schreiben wir eine duale Zahl als

$$x + \varepsilon y, \qquad x, y \in \mathbb{R},$$

ähnlich wie eine komplexe Zahl

$$z = x + \mathrm{i} y, \qquad x, y \in \mathbb{R}.$$

Allerdings erfüllt das neue Basis-Element $\varepsilon$

$$\varepsilon^2 = 0$$

statt $\mathrm{i}^2 = -1$. Daher haben duale Zahlen die Struktur einer
*Algebra* statt eines *Körpers* wie die komplexen Zahlen $\mathbb{C}$.

In unserer Anwendung wird der $\varepsilon$ die Ableitungen enthalten.
In der Tat ist mit $\varepsilon^2 = 0$

$$(a + \varepsilon b) (c + \varepsilon d) = a c + \varepsilon (a d + b c),$$

was nichts Anderes als die Produktregel ist. Das können wir wie folgt
implementieren.
"""

# ╔═╡ a7195ecb-5e70-4abc-880c-063533944e91
begin
	struct MyDual{T <: Real} <: Number
		value::T
		deriv::T
	end
	MyDual(x::Real, y::Real) = MyDual(promote(x, y)...)
end

# ╔═╡ be74e9c0-cd17-47c5-9656-8109db96897a
md"Jetzt können wir duale Zahlen erstellen."

# ╔═╡ dde0b734-1c54-4a54-b112-b256506fa0a6
MyDual(5, 2.0)

# ╔═╡ 927cbfbd-daa8-47ff-b100-6c0d81b5ea82
md"Als nächstes implementieren wir das Interface für Zahlen in Julia."

# ╔═╡ 1437a1cc-dddd-4d4f-be18-81ab0f92950b
Base.:+(x::MyDual, y::MyDual) = MyDual(x.value + y.value, x.deriv + y.deriv)

# ╔═╡ af3ea3f6-0b4e-4cf1-9aa7-d619fa4e846c
MyDual(1, 2) + MyDual(2.0, 3)

# ╔═╡ 7c60e778-b116-4504-a60a-72c52d91fd9d
Base.:-(x::MyDual, y::MyDual) = MyDual(x.value - y.value, x.deriv - y.deriv)

# ╔═╡ 1f97ab58-580d-4069-992f-f611312bc71f
MyDual(1, 2) - MyDual(2.0, 3)

# ╔═╡ 84a6bc63-8e55-45ed-a6b8-150a0bf3f22a
function Base.:*(x::MyDual, y::MyDual)
	MyDual(x.value * y.value, x.value * y.deriv + x.deriv * y.value)
end

# ╔═╡ a7cb831e-49bf-4a16-bc5e-118d31a069bd
MyDual(1, 2) * MyDual(2.0, 3)

# ╔═╡ 48b60e62-3879-4693-9540-c35a2a5d09c7
function Base.:/(x::MyDual, y::MyDual)
	MyDual(x.value / y.value, (x.deriv * y.value - x.value * y.deriv) / y.value^2)
end

# ╔═╡ d2014f18-ca17-4a6c-8bcc-efeecc7f29d2
MyDual(1, 2) / MyDual(2.0, 3)

# ╔═╡ fd1c6e36-1309-4c85-b0be-6e7a215a4f54
md"Als nächstes müssen wir noch implementieren, wie übliche und duale Zahlen konvertiert werden sollen."

# ╔═╡ 2efd0312-54b4-4c64-a505-11be21ab5c18
Base.convert(::Type{MyDual{T}}, x::Real) where {T <: Real} = MyDual(x, zero(T))

# ╔═╡ a43b5324-fc81-4247-b6b1-4e8f5c367cbe
Base.promote_rule(::Type{MyDual{T}}, ::Type{<:Real}) where {T <: Real} = MyDual{T}

# ╔═╡ 79544ce2-6bf0-4cd6-a4f2-ab2122d9bc49
MyDual(1, 2) + 3.0

# ╔═╡ fbc63b55-5d04-4b70-8dd4-f5b3eff6d99f
md"Jetzt implementieren wir die Ableitungen spezieller Funktionen, die wir im Beispiel brauchen."

# ╔═╡ d4ad273b-b548-43c3-9e69-807b47bace27
function Base.sin(x::MyDual)
	si, co = sincos(x.value)
	return MyDual(si, co * x.deriv)
end

# ╔═╡ bb22987a-c3b8-4242-8a3e-91f773841b40
sin(MyDual(π, 1))

# ╔═╡ 7421edea-ec1c-47cb-9b19-77d9203d6857
function Base.cos(x::MyDual)
	si, co = sincos(x.value)
	return MyDual(co, -si * x.deriv)
end

# ╔═╡ 7e76a3bf-a750-4f8c-a28a-d44505d3526f
cos(MyDual(π, 1))

# ╔═╡ 26659be3-07ea-4844-9f91-0490faa5a082
Base.log(x::MyDual) = MyDual(log(x.value), x.deriv / x.value)

# ╔═╡ 5695da28-2297-418b-92db-4c2271edbefd
log(MyDual(1.0, 1))

# ╔═╡ e9e02a31-9b3c-412c-84a9-8490a664715b
function Base.exp(x::MyDual)
	e = exp(x.value)
	return MyDual(e, e * x.deriv)
end

# ╔═╡ a7d5feb5-c3c5-4d55-b721-f9a838a22e78
f(x) = log(x^2 + exp(sin(x)))

# ╔═╡ ff0adc67-3dd9-4402-b033-63a843dc8790
let x = 1.0, h = sqrt(eps())
	(f(x + h) - f(x)) / h
end

# ╔═╡ b8b74818-30f8-4219-b293-657025589a44
f′(x) = 1 / (x^2 + exp(sin(x))) * (2 * x + exp(sin(x)) * cos(x))

# ╔═╡ 56f7e83d-6d8f-413c-a2bb-fd89bebd28b5
(f(1.0), f′(1.0))

# ╔═╡ 48768b89-edf4-4c69-99ad-d304d2700bb4
function f_graph(x)
	c1 = x^2
	c2 = sin(x)
	c3 = exp(c2)
	c4 = c1 + c3
	c5 = log(c4)
	return c5
end

# ╔═╡ 43ef27fd-a67d-4cf8-a8e6-3d11880b5eac
f(1.0) ≈ f_graph(1.0)

# ╔═╡ 2558317b-14e6-4871-9bd3-5b26be391019
function f_graph_derivative(x)
	c1 = x^2
	c1_ε = 2 * x
	
	c2 = sin(x)
	c2_ε = cos(x)
	
	c3 = exp(c2)
	c3_ε = exp(c2) * c2_ε
	
	c4 = c1 + c3
	c4_ε = c1_ε + c3_ε
	
	c5 = log(c4)
	c5_ε = c4_ε / c4
	return c5, c5_ε
end

# ╔═╡ c660ccf1-5bff-44f1-92b5-10465011748e
f_graph_derivative(1.0)

# ╔═╡ 4e4ad771-736b-4789-8ed0-43d2e1799b40
exp(MyDual(1.0, 1))

# ╔═╡ bc2c6be4-10a9-4cb9-be8e-aa64745c32ba
md"Damit können wir die Funktion `f` aus dem Beispiel differenzieren!"

# ╔═╡ d45ce0d3-d23d-41ce-af4d-4946c3a37253
let
	f_dual = f(MyDual(1.0, 1.0))
	(f_dual.value, f_dual.deriv) .- (f(1.0), f′(1.0))
end

# ╔═╡ c9b56c8c-38af-4069-b2fe-4c4cf0753f6c
let
	f_dual = f(MyDual(1.0, 1.0))
	(f_dual.value, f_dual.deriv) .- f_graph_derivative(1.0)
end

# ╔═╡ 625d13ec-ce64-4330-9842-2e1596827079
md"""
Das funktioniert, weil der Compiler im Wesentlichen die Transformation 
`f` $\to$ `f_graph_derivative` für uns übernimmt. Wir können dies auch
Wesentlichen, indem wir die verschiedenen Schritte in der Compiler-Pipeline
von Julia betrachten.
"""

# ╔═╡ 26238234-602d-4117-ab56-120dbecb1130
@code_typed f(MyDual(1.0, 1.0))

# ╔═╡ 1664e082-9ae2-4deb-9268-c03861aa49b2
@code_typed f_graph_derivative(1.0)

# ╔═╡ 0f210d38-f8be-470c-ab1e-1baeae951482
md"Weil der Compiler alle Schritte sieht, kann effizienter Code generiert werden."

# ╔═╡ f3a85308-8448-4458-b224-e2bd1ee48077
@benchmark f_graph_derivative($(Ref(1.0))[])

# ╔═╡ 17421bbd-9e8d-475e-be20-b46da8cc6449
@benchmark f(MyDual($(Ref(1.0))[], 1.0))

# ╔═╡ 74ebd661-8242-431d-8163-d1bbfcee52da
md"Damit können wir jetzt Ableitungen von Funktionen einer Variablen berechnen."

# ╔═╡ 63c9cd60-64b6-4755-b3b2-96174882f618
derivative(f, x::Real) = f(MyDual(x, one(x))).deriv

# ╔═╡ acf3dc94-3a21-4bce-862e-93ccb4d44b3a
md"Wir können auch die Ableitung als Funktion erhalten."

# ╔═╡ 252caf68-b944-4f30-98ae-dc40482ef1a6
derivative(f) = x -> derivative(f, x)

# ╔═╡ 2f5bc87b-7675-42d0-bd86-6503403a3404
derivative(f, 1.0)

# ╔═╡ af152a4f-46f9-4bc1-8b87-ff7b3fd908d5
derivative(x -> 3 * x^2 + 4 * x + 5, 2)

# ╔═╡ e128836c-1fac-46ba-9db5-3803fa090759
derivative(3) do x
	sin(x) * log(x)
end

# ╔═╡ c6230689-5f2a-4f57-ad03-8d87423fa5a2
let df = derivative(f)
	x = range(0.1, 10.0, length = 10)
	df.(x) - f′.(x)
end

# ╔═╡ 698c4bd2-29f9-4830-918f-3b55395d861c
md"""
## Weiterführende Quellen

Es gibt viel Material über AD (in Julia), zum Beispiel

- [Enzyme.jl](https://github.com/EnzymeAD/Enzyme.jl)
- [ForwardDiff.jl](https://github.com/JuliaDiff/ForwardDiff.jl)
- [Lecture notes "Advanced Topics from Scientific Computing" by Jürgen Fuhrmann](https://www.wias-berlin.de/people/fuhrmann/AdSciComp-WS2324/)
- [https://dj4earth.github.io/MPE24](https://dj4earth.github.io/MPE24/)
- [A JuliaLabs workshop](https://github.com/JuliaLabs/Workshop-OIST/blob/master/Lecture%203b%20--%20AD%20in%2010%20minutes.ipynb)
"""

# ╔═╡ 4340e86a-e0fe-4cfe-9d1a-9bb686cbb2fd
md"""
# Appendix

You can find code and utility material in this appendix.
"""

# ╔═╡ 42fa44f5-06df-41a1-9b33-71386a0cb6d2
space = html"<br><br><br>";

# ╔═╡ 96351793-9bcc-4376-9c95-b6b42f061ad8
space

# ╔═╡ bc148aac-1ef7-4611-b187-72f1255ff05f
space

# ╔═╡ 92377a23-ac4f-4d5f-9d57-a0a03693307c
space

# ╔═╡ e771a1f9-6813-4383-b34d-83530de4aa2e
md"""
#### Installing packages

_First, we will install (and compile) some packages. This can take a few minutes when  running this notebook for the first time._
"""


# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
BenchmarkTools = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
Enzyme = "7da242da-08ed-463a-9acd-ee780be4f1d9"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
BenchmarkTools = "~1.6.2"
Enzyme = "~0.13.86"
PlutoUI = "~0.7.72"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.10.10"
manifest_format = "2.0"
project_hash = "7eb7fc53caa7b73630926bb58192b3a9ce5f1833"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "6e1d2a35f2f90a4bc7c2ed98079b2ba09c35b83a"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.3.2"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.BenchmarkTools]]
deps = ["Compat", "JSON", "Logging", "Printf", "Profile", "Statistics", "UUIDs"]
git-tree-sha1 = "67797b8a2ab55dcfcd19529454e5d53669b1350c"
uuid = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
version = "1.6.2"

[[deps.CEnum]]
git-tree-sha1 = "389ad5c84de1ae7cf0e28e381131c98ea87d54fc"
uuid = "fa961155-64e5-5f13-b03f-caf6b980ea82"
version = "0.5.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "67e11ee83a43eb71ddc950302c53bf33f0690dfe"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.12.1"

    [deps.ColorTypes.extensions]
    StyledStringsExt = "StyledStrings"

    [deps.ColorTypes.weakdeps]
    StyledStrings = "f489334b-da3d-4c2e-b8f0-e476e12c162b"

[[deps.Compat]]
deps = ["TOML", "UUIDs"]
git-tree-sha1 = "9d8a54ce4b17aa5bdce0ea5c34bc5e7c340d16ad"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.18.1"
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.1.1+0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.Enzyme]]
deps = ["CEnum", "EnzymeCore", "Enzyme_jll", "GPUCompiler", "InteractiveUtils", "LLVM", "Libdl", "LinearAlgebra", "ObjectFile", "PrecompileTools", "Preferences", "Printf", "Random", "SparseArrays"]
git-tree-sha1 = "9895c1784cfabb101ee51f3461b132083729a1de"
uuid = "7da242da-08ed-463a-9acd-ee780be4f1d9"
version = "0.13.86"

    [deps.Enzyme.extensions]
    EnzymeBFloat16sExt = "BFloat16s"
    EnzymeChainRulesCoreExt = "ChainRulesCore"
    EnzymeDynamicPPLExt = ["ADTypes", "DynamicPPL"]
    EnzymeGPUArraysCoreExt = "GPUArraysCore"
    EnzymeLogExpFunctionsExt = "LogExpFunctions"
    EnzymeSpecialFunctionsExt = "SpecialFunctions"
    EnzymeStaticArraysExt = "StaticArrays"

    [deps.Enzyme.weakdeps]
    ADTypes = "47edcb42-4c32-4615-8424-f2b9edc5f35b"
    BFloat16s = "ab4f0b2a-ad5b-11e8-123f-65d77653426b"
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    DynamicPPL = "366bfd00-2699-11ea-058f-f148b4cae6d8"
    GPUArraysCore = "46192b85-c4d5-4398-a991-12ede77f4527"
    LogExpFunctions = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
    SpecialFunctions = "276daf66-3868-5448-9aa4-cd146d93841b"
    StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"

[[deps.EnzymeCore]]
git-tree-sha1 = "e059db5d02720ae826445f5ce2fdfb3d53236b87"
uuid = "f151be2c-9106-41f4-ab19-57ee4f262869"
version = "0.8.14"

    [deps.EnzymeCore.extensions]
    AdaptExt = "Adapt"

    [deps.EnzymeCore.weakdeps]
    Adapt = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"

[[deps.Enzyme_jll]]
deps = ["Artifacts", "JLLWrappers", "LazyArtifacts", "Libdl", "TOML"]
git-tree-sha1 = "edcca3037addd6402706e435b0551bddd9d14840"
uuid = "7cc45869-7501-5eee-bdea-0790c847d4ef"
version = "0.0.203+1"

[[deps.ExprTools]]
git-tree-sha1 = "27415f162e6028e81c72b82ef756bf321213b6ec"
uuid = "e2ba6199-217a-4e67-a87a-7c52f15ade04"
version = "0.1.10"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "05882d6995ae5c12bb5f36dd2ed3f61c98cbb172"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.5"

[[deps.GPUCompiler]]
deps = ["ExprTools", "InteractiveUtils", "LLVM", "Libdl", "Logging", "PrecompileTools", "Preferences", "Scratch", "Serialization", "TOML", "Tracy", "UUIDs"]
git-tree-sha1 = "9a8b92a457f55165923fcfe48997b7b93b712fca"
uuid = "61eb1bfa-7361-4325-ad38-22787b887f55"
version = "1.7.2"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "179267cfa5e712760cd43dcae385d7ea90cc25a4"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.5"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "7134810b1afce04bbc1045ca1985fbe81ce17653"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.5"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "b6d6bfdd7ce25b0f9b2f6b3dd56b2673a66c8770"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.5"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.JLLWrappers]]
deps = ["Artifacts", "Preferences"]
git-tree-sha1 = "0533e564aae234aff59ab625543145446d8b6ec2"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.7.1"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

[[deps.LLVM]]
deps = ["CEnum", "LLVMExtra_jll", "Libdl", "Preferences", "Printf", "Unicode"]
git-tree-sha1 = "ce8614210409eaa54ed5968f4b50aa96da7ae543"
uuid = "929cbde3-209d-540e-8aea-75f648917ca0"
version = "9.4.4"

    [deps.LLVM.extensions]
    BFloat16sExt = "BFloat16s"

    [deps.LLVM.weakdeps]
    BFloat16s = "ab4f0b2a-ad5b-11e8-123f-65d77653426b"

[[deps.LLVMExtra_jll]]
deps = ["Artifacts", "JLLWrappers", "LazyArtifacts", "Libdl", "TOML"]
git-tree-sha1 = "8e76807afb59ebb833e9b131ebf1a8c006510f33"
uuid = "dad2f222-ce93-54a1-a47d-0025e8a3acab"
version = "0.0.38+0"

[[deps.LazyArtifacts]]
deps = ["Artifacts", "Pkg"]
uuid = "4af54fe1-eca0-43a8-85a7-787d91b784e3"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.4"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "8.4.0+0"

[[deps.LibGit2]]
deps = ["Base64", "LibGit2_jll", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibGit2_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll"]
uuid = "e37daf67-58a4-590a-8e99-b0245dd2ffc5"
version = "1.6.4+0"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.11.0+1"

[[deps.LibTracyClient_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "d2bc4e1034b2d43076b50f0e34ea094c2cb0a717"
uuid = "ad6e5548-8b26-5c9f-8ef3-ef0ad883f3a5"
version = "0.9.1+6"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.LinearAlgebra]]
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.MIMEs]]
git-tree-sha1 = "c64d943587f7187e751162b3b84445bbbd79f691"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "1.1.0"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.2+1"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2023.1.10"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.ObjectFile]]
deps = ["Reexport", "StructIO"]
git-tree-sha1 = "22faba70c22d2f03e60fbc61da99c4ebfc3eb9ba"
uuid = "d8793406-e978-5875-9003-1fc021f44a92"
version = "0.5.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.23+4"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "7d2f8f21da5db6a806faf7b9b292296da42b2810"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.8.3"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.10.0"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "Downloads", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "f53232a27a8c1c836d3998ae1e17d898d4df2a46"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.72"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "5aa36f7049a63a1528fe8f7c3f2113413ffd4e1f"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.2.1"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "0f27480397253da18fe2c12a4ba4eb9eb208bf3d"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.5.0"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.Profile]]
deps = ["Printf"]
uuid = "9abbd945-dff8-562f-b5e8-e1ebf5ef1b79"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Scratch]]
deps = ["Dates"]
git-tree-sha1 = "9b81b8393e50b7d4e6d0a9f14e192294d3b7c109"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.3.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
version = "1.10.0"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.10.0"

[[deps.StructIO]]
git-tree-sha1 = "c581be48ae1cbf83e899b14c07a807e1787512cc"
uuid = "53d494c1-5632-5724-8f4c-31dff12d585f"
version = "0.3.1"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "7.2.1+1"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.Tracy]]
deps = ["ExprTools", "LibTracyClient_jll", "Libdl"]
git-tree-sha1 = "73e3ff50fd3990874c59fef0f35d10644a1487bc"
uuid = "e689c965-62c8-4b79-b2c5-8359227902fd"
version = "0.1.6"

    [deps.Tracy.extensions]
    TracyProfilerExt = "TracyProfiler_jll"

    [deps.Tracy.weakdeps]
    TracyProfiler_jll = "0c351ed6-8a68-550e-8b79-de6f926da83c"

[[deps.Tricks]]
git-tree-sha1 = "372b90fe551c019541fafc6ff034199dc19c8436"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.12"

[[deps.URIs]]
git-tree-sha1 = "bef26fb046d031353ef97a82e3fdb6afe7f21b1a"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.6.1"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+1"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.11.0+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.52.0+1"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+2"
"""

# ╔═╡ Cell order:
# ╟─e6c64c80-773b-11ef-2379-bf6609137e69
# ╟─cd57529b-64a3-43cd-8dbf-445583c8edcc
# ╠═a7d5feb5-c3c5-4d55-b721-f9a838a22e78
# ╟─ee241f76-b1d9-4c00-9b53-020a1ba012dd
# ╠═b8b74818-30f8-4219-b293-657025589a44
# ╟─127944b9-b3eb-4df8-acc3-36d9958218ca
# ╠═48768b89-edf4-4c69-99ad-d304d2700bb4
# ╠═43ef27fd-a67d-4cf8-a8e6-3d11880b5eac
# ╟─a89b42c6-913e-4970-bd9e-8f163a4b96d8
# ╠═2558317b-14e6-4871-9bd3-5b26be391019
# ╠═c660ccf1-5bff-44f1-92b5-10465011748e
# ╠═56f7e83d-6d8f-413c-a2bb-fd89bebd28b5
# ╠═ff0adc67-3dd9-4402-b033-63a843dc8790
# ╟─9777384f-dc51-4d6b-b55f-87b5fd2c5be7
# ╠═a7195ecb-5e70-4abc-880c-063533944e91
# ╟─be74e9c0-cd17-47c5-9656-8109db96897a
# ╠═dde0b734-1c54-4a54-b112-b256506fa0a6
# ╟─927cbfbd-daa8-47ff-b100-6c0d81b5ea82
# ╠═1437a1cc-dddd-4d4f-be18-81ab0f92950b
# ╠═af3ea3f6-0b4e-4cf1-9aa7-d619fa4e846c
# ╠═7c60e778-b116-4504-a60a-72c52d91fd9d
# ╠═1f97ab58-580d-4069-992f-f611312bc71f
# ╠═84a6bc63-8e55-45ed-a6b8-150a0bf3f22a
# ╠═a7cb831e-49bf-4a16-bc5e-118d31a069bd
# ╠═48b60e62-3879-4693-9540-c35a2a5d09c7
# ╠═d2014f18-ca17-4a6c-8bcc-efeecc7f29d2
# ╟─fd1c6e36-1309-4c85-b0be-6e7a215a4f54
# ╠═2efd0312-54b4-4c64-a505-11be21ab5c18
# ╠═a43b5324-fc81-4247-b6b1-4e8f5c367cbe
# ╠═79544ce2-6bf0-4cd6-a4f2-ab2122d9bc49
# ╟─fbc63b55-5d04-4b70-8dd4-f5b3eff6d99f
# ╠═d4ad273b-b548-43c3-9e69-807b47bace27
# ╠═bb22987a-c3b8-4242-8a3e-91f773841b40
# ╠═7421edea-ec1c-47cb-9b19-77d9203d6857
# ╠═7e76a3bf-a750-4f8c-a28a-d44505d3526f
# ╠═26659be3-07ea-4844-9f91-0490faa5a082
# ╠═5695da28-2297-418b-92db-4c2271edbefd
# ╠═e9e02a31-9b3c-412c-84a9-8490a664715b
# ╠═4e4ad771-736b-4789-8ed0-43d2e1799b40
# ╟─bc2c6be4-10a9-4cb9-be8e-aa64745c32ba
# ╠═d45ce0d3-d23d-41ce-af4d-4946c3a37253
# ╠═c9b56c8c-38af-4069-b2fe-4c4cf0753f6c
# ╟─625d13ec-ce64-4330-9842-2e1596827079
# ╠═26238234-602d-4117-ab56-120dbecb1130
# ╠═1664e082-9ae2-4deb-9268-c03861aa49b2
# ╟─0f210d38-f8be-470c-ab1e-1baeae951482
# ╠═f3a85308-8448-4458-b224-e2bd1ee48077
# ╠═17421bbd-9e8d-475e-be20-b46da8cc6449
# ╟─74ebd661-8242-431d-8163-d1bbfcee52da
# ╠═63c9cd60-64b6-4755-b3b2-96174882f618
# ╠═2f5bc87b-7675-42d0-bd86-6503403a3404
# ╠═af152a4f-46f9-4bc1-8b87-ff7b3fd908d5
# ╠═e128836c-1fac-46ba-9db5-3803fa090759
# ╟─acf3dc94-3a21-4bce-862e-93ccb4d44b3a
# ╠═252caf68-b944-4f30-98ae-dc40482ef1a6
# ╠═c6230689-5f2a-4f57-ad03-8d87423fa5a2
# ╟─698c4bd2-29f9-4830-918f-3b55395d861c
# ╟─96351793-9bcc-4376-9c95-b6b42f061ad8
# ╟─bc148aac-1ef7-4611-b187-72f1255ff05f
# ╟─92377a23-ac4f-4d5f-9d57-a0a03693307c
# ╟─4340e86a-e0fe-4cfe-9d1a-9bb686cbb2fd
# ╠═42fa44f5-06df-41a1-9b33-71386a0cb6d2
# ╟─e771a1f9-6813-4383-b34d-83530de4aa2e
# ╠═f05a5972-58b1-4788-a0a8-24966d6714da
# ╠═02ed8724-fbe6-4cdd-bab6-9f7ccfed8380
# ╠═72f1a9ed-3047-4ab9-b038-10c76984c540
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
