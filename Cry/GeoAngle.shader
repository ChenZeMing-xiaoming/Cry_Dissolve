Shader "Unlit/GeoAngle"
{
   Properties
	{
        _MainTex ("Texture", 2D) = "white" {}
		_NoiseTex("noiseTex",2D)="white"{}
		_move_Speed("_move_Speed",float)=3
		_start_pos ("_start_pos",float) = 1
		_start_angle("_start_angle",vector)=(1,0,0,0)
		_rotate_scale("_rotate_scale",float)=13.71
		_size("Size",float)=0
		_melt_speed ("_melt_speed",float) = 0.07
		_melt_range("_melt_range",float)=0.1
		_melt_angle("_melt_angle",vector)=(0,0,0,0)
        _Emossion("Emossion", Color) = (0, 0, 0, 0)
		_expend_range("expend_range",float)=1
		_hide_dis("_hide_dis",float)=5.41

	}

	SubShader
	{
		Pass
		{
			Tags { "RenderType" = "Opaque" "RenderQueue" = "Geometry"}
            Blend SrcAlpha OneMinusSrcAlpha
			LOD 800
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

            };

            struct v2g{
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;

            };

            struct g2f{
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
				float alth:TEXCOORD1;
            };

			sampler2D _MainTex;
			sampler2D _NoiseTex;
			float _size;
			float _start_pos;
			float _melt_speed;
			float _rotate_scale;
			float _move_Speed;
			float _melt_range; 
			float4 _start_angle;
			float4 _melt_angle;
			float _expend_range;
			v2g vert(a2v v) 
			{
				v2g o;
				o.vertex = v.vertex;
			    o.uv = v.uv;
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
            [maxvertexcount(32)]
            void geo(triangle  v2g IN[3], inout TriangleStream<g2f> pointStream){
        
				float4 mid_point_old =(IN[0].vertex+IN[1].vertex+IN[2].vertex)/3.0;
				float4 mid_uv=float4(IN[0].uv+IN[1].uv+IN[2].uv,0,0)/3.0;
		    	float4 noise= tex2Dlod(_NoiseTex,mid_uv);

				float4 start_angle=normalize(_start_angle);
				float4 pannel_point=(_start_pos-noise.z*_melt_range-_Time.y*_melt_speed)*start_angle ;
			    float dis =	start_angle.x*(mid_point_old.x-pannel_point.x)+start_angle.y*(mid_point_old.y-pannel_point.y)+start_angle.z*(mid_point_old.z-pannel_point.z);
		     	dis=max(0,dis)*_move_Speed;


				float4 dir=(normalize(normalize(_melt_angle)- normalize(noise-0.5)*_expend_range)) ;
			
				float4 add_point=dis*dir; 
				float4 mid_point =mid_point_old+add_point;
				float4 an= noise*dis*_rotate_scale;
				float4 cn= mid_point;
				IN[0].vertex+=normalize(IN[0].vertex-mid_point_old)*_size*min(1,dis) ;
				IN[1].vertex+=normalize(IN[1].vertex-mid_point_old)*_size*min(1,dis);
				IN[2].vertex+=normalize(IN[2].vertex-mid_point_old)*_size*min(1,dis);
				float4 a= IN[0].vertex+add_point-mid_point;
				float4 c1=float4(
				(cos(an.y)*cos(an.z)+sin(an.z)*sin(an.y)*sin(an.z))*a.x-(cos(an.y)*sin(an.z)+sin(an.x)*sin(an.y)*cos(an.z))*a.y+cos(an.x)*sin(an.y)*a.z+cn.x,
				cos(an.x)*sin(an.z)*a.x+cos(an.x)*cos(an.z)*a.y-sin(an.x)*a.z+cn.y,
				(-sin(an.y)*cos(an.z)+sin(an.x)*cos(an.y)*sin(an.z))*a.x+(sin(an.y)*sin(an.z)+sin(an.x)*cos(an.y)*cos(an.z))*a.y+cos(an.x)*cos(an.y)*a.z+cn.z,
				 1
				);

				g2f o;
				float4 clip_c1=UnityObjectToClipPos(c1);
				o.vertex =clip_c1;
				o.uv =  IN[0].uv;
				o.alth =dis;
				pointStream.Append(o);
				a= IN[1].vertex+add_point-mid_point;
				float4 c2=float4(
				(cos(an.y)*cos(an.z)+sin(an.z)*sin(an.y)*sin(an.z))*a.x-(cos(an.y)*sin(an.z)+sin(an.x)*sin(an.y)*cos(an.z))*a.y+cos(an.x)*sin(an.y)*a.z+cn.x,
				cos(an.x)*sin(an.z)*a.x+cos(an.x)*cos(an.z)*a.y-sin(an.x)*a.z+cn.y,
				(-sin(an.y)*cos(an.z)+sin(an.x)*cos(an.y)*sin(an.z))*a.x+(sin(an.y)*sin(an.z)+sin(an.x)*cos(an.y)*cos(an.z))*a.y+cos(an.x)*cos(an.y)*a.z+cn.z,
				 1
				);
				float4 clip_c2=UnityObjectToClipPos(c2);
				o.vertex =clip_c2;
				o.uv =  IN[1].uv;
				o.alth =dis;
				pointStream.Append(o);
				 a= IN[2].vertex+add_point-mid_point;
				float4 c3=float4(
				(cos(an.y)*cos(an.z)+sin(an.z)*sin(an.y)*sin(an.z))*a.x-(cos(an.y)*sin(an.z)+sin(an.x)*sin(an.y)*cos(an.z))*a.y+cos(an.x)*sin(an.y)*a.z+cn.x,
				cos(an.x)*sin(an.z)*a.x+cos(an.x)*cos(an.z)*a.y-sin(an.x)*a.z+cn.y,
				(-sin(an.y)*cos(an.z)+sin(an.x)*cos(an.y)*sin(an.z))*a.x+(sin(an.y)*sin(an.z)+sin(an.x)*cos(an.y)*cos(an.z))*a.y+cos(an.x)*cos(an.y)*a.z+cn.z,
				 1
				);


				float4 clip_c3=UnityObjectToClipPos(c3);
				o.vertex =clip_c3;
				o.uv =  IN[2].uv;
				o.alth =dis;
				pointStream.Append(o);
				pointStream.RestartStrip();
				



				float4 Dic1=mid_point-c1;
				float4 Dic2=c2-mid_point;
			    float4 Dic_normal=normalize(float4(cross(Dic1.xyz,Dic2.xyz),0));
			    float4	Point_normal =UnityObjectToClipPos(mid_point+Dic_normal*abs(Dic1.x)*saturate(dis)) ;
				o.vertex =clip_c1;
				o.uv =  IN[0].uv;
				o.alth =dis;
				pointStream.Append(o);
				o.vertex =clip_c2;
				o.uv =  IN[1].uv;
				o.alth =dis;
				pointStream.Append(o);
				o.vertex =Point_normal;
				o.uv =  mid_uv;
				o.alth =dis;
				pointStream.Append(o);
				pointStream.RestartStrip();


				o.vertex =clip_c2;
				o.uv =  IN[1].uv;
				o.alth =dis;
				pointStream.Append(o);
				o.vertex =clip_c3;
				o.uv =  IN[2].uv;
				o.alth =dis;
				pointStream.Append(o);
				o.vertex =Point_normal;
				o.uv =  mid_uv;
				o.alth =dis;
				pointStream.Append(o);
				pointStream.RestartStrip();


				o.vertex =clip_c3;
				o.uv =  IN[2].uv;
				o.alth =dis;
				pointStream.Append(o);
				o.vertex =clip_c1;
				o.uv =  IN[0].uv;
				o.alth =dis;
				pointStream.Append(o);
				o.vertex =Point_normal;
				o.uv =  mid_uv;
				o.alth =dis;
				pointStream.Append(o);
				pointStream.RestartStrip();

				o.vertex =clip_c3;
				o.uv =  IN[2].uv;
				o.alth =dis;
				pointStream.Append(o);
				o.vertex =clip_c2;
				o.uv =  IN[1].uv;
				o.alth =dis;
				pointStream.Append(o);
				o.vertex =clip_c1;
				o.uv =  IN[0].uv;
				o.alth =dis;
				pointStream.Append(o);
				pointStream.RestartStrip();

            }
			half4 _Emossion;
			float _hide_dis;
			fixed4 frag(g2f i) : SV_Target
			{
		    	float4 noise= tex2D(_NoiseTex,i.uv);
			    fixed4 cc=tex2D(_MainTex,i.uv);
		    	return fixed4(cc.rgb+_Emossion.rgb*saturate (i.alth)*noise.rgb, cc.a*saturate (_hide_dis-i.alth+1));
			}

			ENDCG
		}
    }
}
