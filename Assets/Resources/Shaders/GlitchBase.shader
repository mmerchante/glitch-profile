Shader "GlitchBase"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		//Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}
			
			sampler2D _MainTex;

			#define SOURCE_TEXTURE_COUNT 5

			sampler2D _SourceTexture_0; 
			sampler2D _SourceTexture_1;
			sampler2D _SourceTexture_2;
			sampler2D _SourceTexture_3;
			sampler2D _SourceTexture_4;
			sampler2D _SourceTexture_5;
			sampler2D _SourceTexture_6;

			uint hash_state;
			
			// A single iteration of Bob Jenkins' One-At-A-Time hashing algorithm.
			uint hash( uint x ) 
			{
				x += ( x << 10u );
				x ^= ( x >>  6u );
				x += ( x <<  3u );
				x ^= ( x >> 11u );
				x += ( x << 15u );
				return x;
			}

			float random() 
			{
				hash_state = hash(hash_state);
				return float(hash_state) * (1.0 / 4294967296.0);
			}

			float2 RemapToVideo(float2 uv)
			{			  
				return float2((1.0 - uv.y) * (1080.0 / 1920.0), uv.x);
			}
			
			float vmax(float2 v) {
				return max(v.x, v.y);
			}

			float fBox2Cheap(float2 p, float2 b) {
				return vmax(abs(p)-b);
			}

			float4 sampleSource(float2 uv, int index, int channel)
			{			
				uv = RemapToVideo(uv);

				float4 result = 0.0;
				float4 mask = 0.0;
				mask[channel] = 1.0;				

				if(index == 0)
					result = tex2D(_SourceTexture_0, uv);
				else if(index == 1)
					result = tex2D(_SourceTexture_1, uv);
				else if(index == 2)
					result = tex2D(_SourceTexture_2, uv);
				else if(index == 3)
					result = tex2D(_SourceTexture_3, uv);
				else if(index == 4)
					result = tex2D(_SourceTexture_4, uv);
				else if(index == 5)
					result = tex2D(_SourceTexture_5, uv);
				else if(index == 6)
					result = tex2D(_SourceTexture_6, uv);

				return result * mask;
			}
			
			// Canonical hash function with a biger prime
			float fhash(float x)
			{
				return fmod(sin(x * 7.13) * 268573.103291, 1.0);
			}
			
			float3 palette( float t, float3 a, float3 b, float3 c, float3 d)
			{
				return saturate(a + b * cos(6.28318 * ( c * t + d)));
			}

			float4 frag (v2f i) : SV_Target
			{
				float2 uv = i.uv;
				int index = 0;
				
				for(int b = 0; b < 5; ++b)
				{
					hash_state = 14041956 + uint(_Time.a * (b + 1) * .65);

					for(int c = 0; c < 5; ++c)
					{
						float2 center = .5 + (float2(random(), random()) * 2.0 - 1.0) * .45;
						float2 size = float2(random() * 4.0 + .01, random() * .65 + .05) * .25;

						float d = fBox2Cheap(i.uv - center, size);

						float2 offset = float2(random(), random()) * 2.0 - 1.0;

						uv = lerp(i.uv + offset * lerp(.025, .05, random()), i.uv, step(0.0, d));
						index = hash_state % SOURCE_TEXTURE_COUNT;

						if(d < 0.0)
							break;
					}
				}
				 
				float2 aberration = normalize(float2(random(), random())) * random()  * float2(_CosTime.y, _SinTime.y);
				aberration.x += fhash(floor(i.uv.y * 155.0) + index) * random() * .5 * sin(index);
				
				float4 result = sampleSource(uv, index, 0);
				result += sampleSource(uv + aberration * .05, index, 1);
				result += sampleSource(uv + aberration * .1, index, 2);

				result.b = lerp(.2, 1.0, result.b);
				result.r += .05;

				result = lerp(result, smoothstep(0.0, 1.0, result), .25);
				float3 color = palette(length(result), float3(0.748, 0.638, 0.108), float3(0.748, 1.008, 0.958), float3(0.368, 0.528, 0.428), float3(1.548, -1.602, 0.428));
				result.rgb = lerp(result.rgb, color, random() * .7);

				result = result * 2.0 - .35;

				float vignette = smoothstep(0.0, 1.0, 1.0 - pow(saturate((length(i.uv - .5) / .5)), 1.5));

				result = lerp(result * result * .35, result, vignette * 1.1);

				return result;
			}
			ENDCG
		}
	}
}
