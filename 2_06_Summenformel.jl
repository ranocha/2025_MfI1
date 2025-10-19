### A Pluto.jl notebook ###
# v0.20.19

using Markdown
using InteractiveUtils

# ╔═╡ f05a5972-58b1-4788-a0a8-24966d6714da
begin
	using PlutoUI
	using PlutoUI: Slider
end

# ╔═╡ 5041ee99-ab0a-464c-a914-f7334a6848f6
using BenchmarkTools

# ╔═╡ e6c64c80-773b-11ef-2379-bf6609137e69
md"""
# 2.6 Starke und schwache Induktion: Summenformeln

Die Gaußsche Summenformel

$$\sum_{k=1}^n k = 1 + 2 + \dots + n
    = \frac{n (n + 1)}{2}
    \qquad \text{für alle } n \in \mathbb{N}_+$$

kann mit vollständiger Induktion bewiesen werden. Moderne Compiler wie bspw.
LLVM verwenden solche Identitäten bei der Optimierung.
"""

# ╔═╡ d76a5fac-b781-4729-8c1b-48c4350d612d
function f(n)
	s = 0
	for i in 1:n
		s += i
	end
	return s
end

# ╔═╡ 3bb4c835-63ae-4fea-8284-50ceb890acc2
f(10)

# ╔═╡ 34ba6e89-2f82-4b41-a6af-bc794defbbad
@benchmark f(10)

# ╔═╡ 5c633fff-acb7-453a-8752-422370ae2d54
@benchmark f(10_000)

# ╔═╡ 190faabb-6872-48da-96d2-661f117157c0
with_terminal() do 
	@code_llvm debuginfo=:none f(10)
end

# ╔═╡ 0d4ae36d-ebe6-46db-af1f-ba55c4d40e51
md"""
Der LLVM-Code im preheader übersetzt sich wie folgt:

- `shl`: "shift left": $n \mapsto 2n$
- `add`: $n \mapsto n - 1$
- `zext`: mit 65-Bit-Zahlen arbeiten, um overflow zu verhindern
- `add`: $n \mapsto n - 2$
- `mul`: $(n - 1) (n - 2)$
- `lshr`: "logical shift right", $(n - 1) (n - 2) \mapsto (n - 1) (n - 2) / 2$
- `trunc`: wieder als 64-Bit-Zahl verwenden
- `add`: $2n + (n - 1) (n - 2) / 2$
- `add`: $2n + (n - 1) (n - 2) / 2 - 1$

Dies ist genau das Ergebnis der Gaußschen Summenformel, denn

$$\begin{equation*}
\begin{aligned}
2n + \frac{(n - 1) (n - 2)}{2} - 1
&= 2n + \frac{n^2 - 3 n + 2}{2} - 1
\\
&= \frac{4n + n^2 - 3n + 2 - 2}{2}
\\
&= \frac{n^2 + n}{2}
\\
&= \frac{n (n + 1)}{2}.
\end{aligned}
\end{equation*}$$


"""

# ╔═╡ 6a6ff1a4-d75b-414d-ad33-ec47faa95a5c
md"""
## Summenformel der Quadrate
"""

# ╔═╡ 9dd9e8b0-4100-422a-b96d-2e3f3081f493
md"""
Analog erhält man
"""

# ╔═╡ 2486d814-e6eb-4c0f-ab3b-cc2224f53f20
function f2(n)
	s = 0
	for i in 1:n
		s += i^2
	end
	return s
end

# ╔═╡ b4794766-9a09-4297-8d25-f4b37372af6b
f2(10)

# ╔═╡ b05ebbc0-8f8c-407c-bf9b-2cf5c705150d
@benchmark f2(10)

# ╔═╡ 906da9ae-4ce8-4a8a-9c12-1ab939875cc3
@benchmark f2(10_000)

# ╔═╡ e3e6d87c-cfdb-4bab-9b78-7eda15a48de7
with_terminal() do 
	@code_llvm debuginfo=:none f2(10)
end

# ╔═╡ b2893c97-64e2-44d9-a2c2-dcf3bb1b768f
md"""
Warum die "magische Konstante" `6148914691236517206` dort auftaucht, werden wir später bei der Division mit Rest im Rahmen der elementaren Zahlentheorie erklären.
"""

# ╔═╡ 91b479c0-819d-4fc3-844b-c9c58e5267f0
md"""
## Summe der Kubikzahlen
"""

# ╔═╡ 730bc1a3-30ab-4cfd-80a3-994f40fa3835
function f3(n)
	s = 0
	for i in 1:n
		s += i^3
	end
	return s
end

# ╔═╡ 32d8141f-d0ce-48a3-94eb-02500b95f798
@benchmark f3(10)

# ╔═╡ 1dc0c9ca-c638-420a-ab70-654c7f2f0f6a
@benchmark f3(10_000)

# ╔═╡ bc4c1734-192d-4e59-8e10-af2c3e2eac1d
with_terminal() do 
	@code_llvm debuginfo=:none f3(10)
end

# ╔═╡ e9ebee2c-f2d3-435f-8300-9bee6f6a581a
md"""
Das sieht schon etwas komplizierter aus, ist aber immer noch ein Polynom in `n` und keine Schleife!
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
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
BenchmarkTools = "~1.6.0"
PlutoUI = "~0.7.71"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.10.10"
manifest_format = "2.0"
project_hash = "c00e040fade89c080e4c0a22c95d7ff658cba6e5"

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
git-tree-sha1 = "e38fbc49a620f5d0b660d7f543db1009fe0f8336"
uuid = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
version = "1.6.0"

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

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "05882d6995ae5c12bb5f36dd2ed3f61c98cbb172"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.5"

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

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "31e996f0a15c7b280ba9f76636b3ff9e2ae58c9a"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.4"

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
git-tree-sha1 = "8329a3a4f75e178c11c1ce2342778bcbbbfa7e3c"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.71"

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
# ╠═d76a5fac-b781-4729-8c1b-48c4350d612d
# ╠═3bb4c835-63ae-4fea-8284-50ceb890acc2
# ╠═34ba6e89-2f82-4b41-a6af-bc794defbbad
# ╠═5c633fff-acb7-453a-8752-422370ae2d54
# ╠═190faabb-6872-48da-96d2-661f117157c0
# ╟─0d4ae36d-ebe6-46db-af1f-ba55c4d40e51
# ╟─6a6ff1a4-d75b-414d-ad33-ec47faa95a5c
# ╟─9dd9e8b0-4100-422a-b96d-2e3f3081f493
# ╠═2486d814-e6eb-4c0f-ab3b-cc2224f53f20
# ╠═b4794766-9a09-4297-8d25-f4b37372af6b
# ╠═b05ebbc0-8f8c-407c-bf9b-2cf5c705150d
# ╠═906da9ae-4ce8-4a8a-9c12-1ab939875cc3
# ╠═e3e6d87c-cfdb-4bab-9b78-7eda15a48de7
# ╟─b2893c97-64e2-44d9-a2c2-dcf3bb1b768f
# ╟─91b479c0-819d-4fc3-844b-c9c58e5267f0
# ╠═730bc1a3-30ab-4cfd-80a3-994f40fa3835
# ╠═32d8141f-d0ce-48a3-94eb-02500b95f798
# ╠═1dc0c9ca-c638-420a-ab70-654c7f2f0f6a
# ╠═bc4c1734-192d-4e59-8e10-af2c3e2eac1d
# ╟─e9ebee2c-f2d3-435f-8300-9bee6f6a581a
# ╟─96351793-9bcc-4376-9c95-b6b42f061ad8
# ╟─bc148aac-1ef7-4611-b187-72f1255ff05f
# ╟─92377a23-ac4f-4d5f-9d57-a0a03693307c
# ╟─4340e86a-e0fe-4cfe-9d1a-9bb686cbb2fd
# ╠═42fa44f5-06df-41a1-9b33-71386a0cb6d2
# ╟─e771a1f9-6813-4383-b34d-83530de4aa2e
# ╠═f05a5972-58b1-4788-a0a8-24966d6714da
# ╠═5041ee99-ab0a-464c-a914-f7334a6848f6
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
