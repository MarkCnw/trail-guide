import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:svg_flutter/svg.dart';
import 'package:trail_guide/features/p2p/presentation/widgets/room_list_shimmer.dart';
import '../../../onboarding/presentation/cubit/onboarding_cubit.dart';
import '../bloc/p2p_bloc.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage>
    with SingleTickerProviderStateMixin {
  // Animation สำหรับตอนกำลังค้นหา (Ripple Effect เบาๆ)
  late AnimationController _controller;

  String _userName = "TrailGuide Member";
  late P2PBloc _p2pBloc;

  // ตัวแปรสำหรับ PIN Input
  final _pinController = TextEditingController();
  bool _showPinInput = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _p2pBloc = context.read<P2PBloc>();

    // ✅ ส่วนที่แก้: ดึงชื่อจริงจาก Cubit แล้วค่อยเริ่ม Scan
    final onboardingState = context.read<OnboardingCubit>().state;
    if (onboardingState is OnboardingLoaded &&
        onboardingState.profile.nickname != null) {
      _userName = onboardingState.profile.nickname!;
    } else {
      // ถ้ายังไม่มีข้อมูล ให้ตั้งชื่อชั่วคราวกัน error
      _userName = "Member-${DateTime.now().millisecond}";
    }

    // เริ่มค้นหาด้วยชื่อที่ถูกต้อง
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print(
        "🚀 Starting discovery as: $_userName",
      ); // เช็ค Log ได้ว่าชื่อถูกไหม
      _p2pBloc.add(StartDiscoveryEvent(_userName));
    });
  }

  @override
  void dispose() {
    // สั่งหยุดค้นหาเมื่อออกจากหน้านี้ (สำคัญมาก ห้ามลบ)
    _p2pBloc.add(StopDiscoveryEvent());
    _controller.dispose();
    _pinController.dispose();
    super.dispose();
  }

  // ฟังก์ชันค้นหา Host ด้วย PIN (Logic เดิม)
  void _joinWithPin() {
    final pin = _pinController.text.trim();
    if (pin.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("กรุณาใส่ PIN 6 หลัก"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final p2pState = context.read<P2PBloc>().state;
    if (p2pState is P2PUpdated) {
      try {
        final matchingPeer = p2pState.peers.firstWhere(
          (peer) => peer.name.contains("#$pin"),
        );
        _connectToPeer(matchingPeer.id, matchingPeer.name);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("ไม่พบห้องที่ตรงกับ PIN นี้"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("ระบบยังไม่พร้อม กรุณารอสักครู่"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // แยกฟังก์ชัน Connect ออกมาเพื่อใช้ซ้ำ
  void _connectToPeer(String id, String name) {
    context.read<P2PBloc>().add(ConnectToPeerEvent(id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(width: 12),
            Text("กำลังเข้าร่วมทีม ${name.split('#')[0]}..."),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<P2PBloc, P2PState>(
      listener: (context, state) {
        if (state is P2PConnected) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          context.go('/lobby');
        }
        if (state is P2PError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F5F2),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black87),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.black87,
            ),
            onPressed: () {
              context.read<P2PBloc>().add(StopDiscoveryEvent());
              context.pop();
            },
          ),
          title: const Text(
            "Nearby Teams",
            style: TextStyle(
              color: Colors.black87, // ☀️ LIGHT MODE: ตัวหนังสือสีดำ
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          centerTitle: true,
          actions: [
            // ปุ่ม Refresh
            IconButton(
              icon: const Icon(
                Icons.refresh_rounded,
                color: Colors.black87,
              ),
              onPressed: () {
                context.read<P2PBloc>().add(
                  StartDiscoveryEvent(_userName),
                );
              },
            ),
            // ปุ่มสลับโหมด PIN
            Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: _showPinInput ? Colors.green[50] : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                // ✅ ใช้เงื่อนไขเลือก Widget ทั้งก้อน ไม่ใช่แค่เลือกข้อมูลข้างใน
                icon: _showPinInput
                    ? const Icon(
                        Icons.podcasts_rounded,
                        color: Colors.green,
                      )
                    : SvgPicture.asset(
                        'assets/icons/navigation/passkey_47dp_000000_FILL0_wght400_GRAD0_opsz48.svg', // 👈 ใส่ path ไฟล์ SVG ของคุณที่นี่
                        width: 30, // กำหนดขนาดให้เท่ากับ Icon มาตรฐาน
                        height: 30,
                        // วิธีกำหนดสีให้ SVG (ถ้าต้องการเปลี่ยนสีตามโค้ด)
                        colorFilter: const ColorFilter.mode(
                          Colors.black87,
                          BlendMode.srcIn,
                        ),
                      ),
                onPressed: () =>
                    setState(() => _showPinInput = !_showPinInput),
                tooltip: _showPinInput ? "List Mode" : "PIN Mode",
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Header Status Bar
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _showPinInput
                    ? _buildPinInputMode()
                    : _buildRoomListMode(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🆕 โหมดรายการห้อง (Room List)
  // ... (โค้ดส่วนอื่นๆ คงเดิม) ...

  // 1. ฟังก์ชันเลือกรูปตามชื่อ (เพื่อสุ่ม Avatar ให้ Host)
  String _getAvatarAsset(String nickname) {
    final List<String> avatars = [
      'assets/Illustration/b1.svg',
      // 'assets/Illustration/b2.svg', // เพิ่มรูปอื่นๆ ได้ที่นี่
    ];
    if (nickname.isEmpty) return avatars[0];
    final int index = nickname.hashCode.abs() % avatars.length;
    return avatars[index];
  }

  // 2. Widget แสดงรายการห้อง (Logic หลัก)
  Widget _buildRoomListMode() {
    return BlocBuilder<P2PBloc, P2PState>(
      builder: (context, state) {
        // -----------------------------------------------------------
        // 🔴 1. กรณี Error -> แสดงปุ่ม Retry
        // -----------------------------------------------------------
        if (state is P2PError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 60,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 16),
                Text(
                  state.message,
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => context.read<P2PBloc>().add(
                    StartDiscoveryEvent(_userName),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text("Try Again"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
          );
        }

        // -----------------------------------------------------------
        // 🟢 2. กรณีเจอห้องแล้ว (Success) -> โชว์ List จริง
        // -----------------------------------------------------------
        if (state is P2PUpdated && state.peers.isNotEmpty) {
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.peers.length,
            separatorBuilder: (c, i) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final peer = state.peers[index];
              final nickname = peer.name.split('#')[0];
              final avatarAsset = _getAvatarAsset(nickname);

              return Container(
                height: 80,
                decoration: BoxDecoration(
                  // 🎨 ใช้สี Dark Mode ให้เข้ากับธีมแอป หรือสีขาวถ้าอยากได้ Contrast
                  // ถ้าเอาตาม Shimmer ที่ให้มา คือ Dark Forest Theme
                  color: const Color(0xFF1A2C1A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      // 1️⃣ Avatar (รูปจริง)
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: Colors.white, // พื้นหลังขาวให้รูปเด่น
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: SvgPicture.asset(
                            avatarAsset,
                            fit: BoxFit.cover,
                            placeholderBuilder: (context) => Icon(
                              Icons.person,
                              color: Colors.green[300],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // 2️⃣ Name & Team Info
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Team",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[400],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              nickname,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors
                                    .white, // สีขาวให้อ่านง่ายบนพื้นเขียว
                                height: 1.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // 3️⃣ Join Button
                      Material(
                        color: Colors.white, // ปุ่มสีขาว
                        borderRadius: BorderRadius.circular(30),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _connectToPeer(peer.id, peer.name),
                          splashColor: Colors.green.withOpacity(0.3),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            child: const Text(
                              "Join",
                              style: TextStyle(
                                color: Color(
                                  0xFF1A2C1A,
                                ), // ตัวหนังสือเขียวเข้ม
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }

        // -----------------------------------------------------------
        // 🟡 3. กรณีโหลด/ยังไม่เจอ (Scanning) -> โชว์ Shimmer
        // -----------------------------------------------------------
        // ใส่ Shimmer ที่คุณสร้างไว้ตรงนี้
        return Column(
          children: [
            // แถบสถานะด้านบน (Optional)

            // 🔥 เรียกใช้ Shimmer Widget ของคุณ
            const Expanded(child: RoomListShimmer()),
          ],
        );
      },
    );
  }

  // โหมดพิมพ์ PIN
  Widget _buildPinInputMode() {
    return Center(
      key: const ValueKey("pin_input"),
      child: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            // ☀️ LIGHT MODE: เงาสีดำจางๆ
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 32,
                  color: Colors.green[700],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Enter Room PIN",
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Enter the 6-digit code from the Host",
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // ช่องพิมพ์ PIN
              TextField(
                controller: _pinController,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
                decoration: InputDecoration(
                  counterText: "",
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Colors.green,
                      width: 2,
                    ),
                  ),
                  hintText: "000000",
                  hintStyle: TextStyle(color: Colors.grey[300]),
                ),
              ),

              const SizedBox(height: 32),

              // ปุ่ม Join
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _joinWithPin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Connect",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => setState(() => _showPinInput = false),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
