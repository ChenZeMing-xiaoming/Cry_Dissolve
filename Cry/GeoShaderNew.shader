Shader "Unlit/GeoShaderNew"
{
   Properties
	{
        _MainTex ("Texture", 2D) = "white" {}
		_NoiseTex("noiseTex",2D)="white"{}
		_start_pos ("_start_pos",float) = 2
		_rotate_scale("_rotate_scale",float)=5
		_melt_speed ("_melt_speed",float) = 1
		_melt_range("_melt_range",float)=1
		_move_Speed("_move_Speed",float)=1 
		_hide_dis("_hide_dis",float)=1
		_Gloss("_Gloss",float)=20
	}

	SubShader 
	{
       Tags { "Queue"="Transparent" }

		Pass
		{
		   Tags{"LightMode"="ForwardBase"}
            Blend SrcAlpha OneMinusSrcAlpha
			CGPROGRAM
			// 1.设置着色器编译目标等级
			#pragma target 4.0

			#pragma vertex vert
			// 2.声明几何着色器方法
			#pragma geometry geo
			#pragma fragment frag
			#include "UnityCG.cginc"

           struct a2v{
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
				float3 normal:NORMAL;
            };

            struct v2g{
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
				float3 normal:NORMAL;
            };

            struct g2f{
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
				float3 normal : TEXCOORD1;
                float4 obj_vertex : TEXCOORD2;
				float alth:TEXCOORD3;
            };

			sampler2D _MainTex;
			sampler2D _NoiseTex;
			float _start_pos;
			float _melt_speed;
			float _rotate_scale;
			float _move_Speed;
			float _melt_range;
			v2g vert(a2v v) 
			{
				v2g o;
				o.vertex = v.vertex;
			    o.uv = v.uv;
				o.normal=v.normal;
                return o;
			}
			float4x4 GetRoateM(float4 an,float4 cn){
				return  float4x4
				(  
				     cos(an.y)*cos(an.z)+sin(an.z)*sin(an.y)*sin(an.z),-cos(an.y)*sin(an.z)+sin(an.x)*sin(an.y)*cos(an.z),cos(an.x)*sin(an.y),cn.x,
				     cos(an.x)*sin(an.z),cos(an.x)*cos(an.z),-sin(an.x),cn.y,
				     -sin(an.y)*cos(an.z)+sin(an.x)*cos(an.y)*sin(an.z),sin(an.y)*sin(an.z)+sin(an.x)*cos(an.y)*cos(an.z),cos(an.x)*cos(an.y),cn.z,
			     	 0,0,0,1
				);

			}

			// 输入: point line triangle 
			// 输出: PointStream LineStream TriangleStream
			// Append
			// triStream.RestartStrip
			// 3.指定几何着色器方法内添加的顶点数
            [maxvertexcount(8)]
            void geo(triangle  v2g IN[3], inout TriangleStream<g2f> pointStream){
        
				float4 mid_point_old =(IN[0].vertex+IN[1].vertex+IN[2].vertex)/3.0;
		    	float4 noise= tex2Dlod(_NoiseTex,float4((IN[0].uv+IN[1].uv+IN[2].uv)/3.0,0,0));
				float  dis=max(0,_Time.y*_melt_speed-_start_pos-noise.z*_melt_range+mid_point_old.x)*_move_Speed;
				float4 dir=normalize(noise);
				float4 add_point=dis*dir; 
				float4 mid_point =mid_point_old+add_point;
				float4 an= noise*dis*_rotate_scale;
				float4 cn= mid_point;
				

				g2f o;

				g2f o_n[3];

                 [unroll]
				for(float i=0;i<3;i++){
				
				float4 a= IN[i].vertex+add_point-mid_point;
				float4 c1=float4(
				(cos(an.y)*cos(an.z)+sin(an.z)*sin(an.y)*sin(an.z))*a.x+(-cos(an.y)*sin(an.z)+sin(an.x)*sin(an.y)*cos(an.z))*a.y+cos(an.x)*sin(an.y)*a.z+cn.x,
				cos(an.x)*sin(an.z)*a.x+cos(an.x)*cos(an.z)*a.y-sin(an.x)*a.z+cn.y,
				(-sin(an.y)*cos(an.z)+sin(an.x)*cos(an.y)*sin(an.z))*a.x+(sin(an.y)*sin(an.z)+sin(an.x)*cos(an.y)*cos(an.z))*a.y+cos(an.x)*cos(an.y)*a.z+cn.z,
				 1
				);
				o.obj_vertex=c1;
				o_n[i].obj_vertex=c1;
				float4 vertex1=UnityObjectToClipPos(c1);
				o.vertex =vertex1;
				o_n[i].vertex=vertex1;
				o.uv =  IN[i].uv;
				o_n[i].uv=IN[i].uv;
				o.alth =dis;
				o_n[i].alth=dis;
				float3 n=IN[i].normal;
				float4 worldNormal1=  float4(
				(cos(an.y)*cos(an.z)+sin(an.z)*sin(an.y)*sin(an.z))*n.x+(-cos(an.y)*sin(an.z)+sin(an.x)*sin(an.y)*sin(an.z))*n.y+cos(an.x)*sin(an.y)*n.z,
				cos(an.x)*sin(an.z)*n.x+cos(an.x)*cos(an.z)*n.y-sin(an.x)*n.z,
				(-sin(an.y)*cos(an.z)+sin(an.x)*cos(an.y)*sin(an.z))*n.x+(sin(an.y)*sin(an.z)+sin(an.x)*cos(an.y)*cos(an.z))*n.y+cos(an.x)*cos(an.y)*n.z,
				 1
				);
				o.normal = worldNormal1;
				o_n[i].normal=-worldNormal1;
				pointStream.Append(o);
				}
				pointStream.RestartStrip();
                 [unroll]
				for(float i=2;i>=0;i--){
				   pointStream.Append(o_n[i]);
				}
				pointStream.RestartStrip();


            }
            float4 _LightColor0;

			float _hide_dis;
			float _Gloss;
			fixed4 frag(g2f i) : SV_Target
			{
                float3 L = normalize(ObjSpaceLightDir(i.obj_vertex));
                float3 N = normalize(i.normal);
                float3 viewDir = normalize(ObjSpaceViewDir(i.obj_vertex));//计算出视线

                float diff = saturate(dot(L, N));
                float3 reflection = normalize(2.0 * N * diff - L);//反射向量
                float spec = pow(max(0, dot(reflection, viewDir)), _Gloss);
                float3 finalSpec = spec;
                //漫反射+镜面高光+环境光
                float3 finalLight = diff * _LightColor0 + finalSpec + UNITY_LIGHTMODEL_AMBIENT;

                fixed4 col = tex2D(_MainTex, i.uv);
                return col * float4(finalLight, saturate (_hide_dis-i.alth));

			}

			ENDCG
		}
    }
}


