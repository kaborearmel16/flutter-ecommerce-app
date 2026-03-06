import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:todo_list/pages/phone_brand_list.dart'; 

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  int _getCrossAxisCount(double width) {
    if (width >= 1200) return 5;
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('promos').snapshots(),
        builder: (context, snapshot) {
          final hasPromo = snapshot.hasData && snapshot.data!.docs.isNotEmpty;

          return CustomScrollView(
            slivers: [

              /// ================= APPBAR COLLAPSABLE =================
              SliverAppBar(
                pinned: true,
                floating: false,
                expandedHeight: hasPromo ? 220 : 0,
                backgroundColor: Colors.white,
                elevation: 0,
                foregroundColor: hasPromo ? Colors.white : Colors.black,

                flexibleSpace: hasPromo
                    ? const PromoSliverAppBar() // 🔥 IMAGE QUI DISPARAÎT AU SCROLL
                    : null,

                title: Container(
                  decoration: hasPromo
                      ? BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(13),
                        )
                      : null,
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  child: Row(
                    children: [
                      const BalanceCard(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 35,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color:  Colors.white,
                            border: hasPromo ? Border.all(color: Colors.green[800]?? Colors.green): Border.all(color: Colors.black),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search, color: Colors.grey),
                              const SizedBox(width: 6),
                              Expanded(
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: "Rechercher un produit",
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),  
                      IconButton(
                        icon: const Icon(Icons.notifications_none),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),

              /// ================= CATEGORIES FIXES =================/// 
               
              SliverPersistentHeader(
                pinned: true,
                delegate: _CategoriesHeaderDelegate(
                  child: 
                  const CategoriesBottomBar(), 
                
                height: 46,)
              ), 

              /// ================= NEW PRODUCTS =================
              /// 👉 On peut aussi faire un SliverToBoxAdapter avec une ListView horizontale à l'intérieur
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 8),
                  child:  NewProductsBar()
                ),
              ),

              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 8),
                  child:  PromoProductsBar()
                ),
              ),

              /// ================= TITLE =================
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(6),
                  child: Text(
                    "For you",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              /// ================= PRODUCTS GRID =================

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                sliver: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("products")
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SliverToBoxAdapter(
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final products = snapshot.data!.docs;

                    return SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final doc = products[index];
                          final data = doc.data() as Map<String, dynamic>;
                          return _productCard(data);
                        },
                        childCount: products.length,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _getCrossAxisCount(width),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.68,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _productCard(Map<String, dynamic> product) {
    final List images = product['images'] ?? [];
    final String imageUrl = images.isNotEmpty ? images[0] : '';
    final bool isPromo = product['isPromo'] ?? false;
    final isFeatured = product['isFeatured'] ?? false;
    final int price = product['price'] ?? 0;

    return GestureDetector(
      onTap: () {
        // 👉 Navigation vers la page produit
      },
      child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: isPromo ? Colors.red : Colors.grey[300] ?? Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Expanded(
            child: Stack( 
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                          )
                        : Container(color: Colors.grey[200]),
                  ),
                ),
                if (isPromo)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _badge("PROMO", Colors.red),
                  ),
              ],
    
            ),
          ), 
          // Info
          Text(
            product['name'] ?? '',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          Text( 
            "$price F",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isPromo ? Colors.red : Colors.black,
            ),
          ),
        ],
      ),
      )
    );
  }
}
 Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }


class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance.collection("Users").doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final balance = data['balance'] ?? 0;

        return InkWell(
          onTap: () {
            // 👉 Action au clic : aller à la page portefeuille
             
          },
          child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                  child: const Icon(Icons.add, color: Colors.white, size: 15,),
                 ),
                const SizedBox(width: 6),
                Text("$balance F", style: const TextStyle(color:Colors.black , fontWeight: FontWeight.bold, fontSize: 14)),
              ],
          )
        ); 
      },
    );
  }
} 

class PromoSliverAppBar extends StatefulWidget {
  const PromoSliverAppBar({super.key});

  @override
  State<PromoSliverAppBar> createState() => _PromoSliverAppBarState();
}

class _PromoSliverAppBarState extends State<PromoSliverAppBar> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;
  bool _autoScrollStarted = false;

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll(int itemCount) {
    if (_autoScrollStarted || itemCount <= 1) return;
    _autoScrollStarted = true;

    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_pageController.hasClients) return;

      _currentPage = (_currentPage + 1) % itemCount;
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('promos')
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final promos = snapshot.data!.docs;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _startAutoScroll(promos.length);
        });

        return FlexibleSpaceBar(
          collapseMode: CollapseMode.parallax,
          background: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: promos.length,
                itemBuilder: (context, index) {
                  final data = promos[index].data() as Map<String, dynamic>;
                  return GestureDetector(
                    onTap: () {
                      final productId = data['linkProductId'];
                      if (productId != null) {
                        // Naviguer vers la page produit
                      }
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          data['imageUrl'],
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Center(child: CircularProgressIndicator());
                          },
                        ),
                        Container(
                          color: Colors.black.withOpacity(0.3), // overlay
                        ),
                        Positioned(
                          bottom: 20,
                          left: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['title'] ?? '',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold),
                              ),
                              Text(
                                data['subtitle'] ?? '',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                },
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class CategoriesBottomBar extends StatefulWidget {
  const CategoriesBottomBar({super.key});

  @override
  State<CategoriesBottomBar> createState() => _CategoriesBottomBarState();
}

class _CategoriesBottomBarState extends State<CategoriesBottomBar> {
  String selectedCategory = "all";

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      color: Colors.white,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("categories") 
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox();
          }

          final cats = snapshot.data!.docs;

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: cats.length + 1, // + All
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildTab("All", "all");
              }

              final data = cats[index - 1].data() as Map<String, dynamic>;
              return _buildTab(data['name'], cats[index - 1].id);
            },
          );
        },
      ),
    );
  }

  Widget _buildTab(String title, String slug) {
    final bool isSelected = selectedCategory == slug;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = slug;
        });

        // 👉 Navigation
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryProductsPage( 
              categoryName: title, 
              categoryId: slug,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
      ),
          
    );
  }
}

class _CategoriesHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _CategoriesHeaderDelegate({
    required this.child,
    required this.height,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.white,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _CategoriesHeaderDelegate oldDelegate) {
    return false;
  }
}

class NewProductsBar extends StatelessWidget {
  const NewProductsBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('isActive', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .limit(10)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox();
          }

          final products = snapshot.data!.docs;

          if (products.isEmpty) {
            return const Center(
              child: Text("Aucune nouveauté"),
            );
          }

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final data = products[index].data() as Map<String, dynamic>;

              final images = List<String>.from(data['images'] ?? []);
              final image = images.isNotEmpty ? images.first : "";

              return _MiniNewProductCard(
                name: data['name'], 
                imageUrl: image,
                onTap: () {},
              );
            },
          );
        },
      ),
    );
  }
}

class PromoProductsBar extends StatelessWidget {
  const PromoProductsBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('isActive', isEqualTo: true)
            .where('isPromo', isEqualTo: true)
            .orderBy('createdAt', descending: true)
            .limit(15)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox();
          }

          final products = snapshot.data!.docs;

          if (products.isEmpty) {
            return const Center(
              child: Text("Aucune promotion en cours"),
            );
          }

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final data = products[index].data() as Map<String, dynamic>;

              final images = List<String>.from(data['images'] ?? []);
              final image = images.isNotEmpty ? images.first : "";

              return _MiniPromoProductCard(
                name: data['name'], 
                imageUrl: image,
                onTap: () {},
              );
            },
          );
        },
      ),
    );
  }
}


class _MiniNewProductCard extends StatelessWidget {
  final String name;
  final String imageUrl; 
  final onTap;

  const _MiniNewProductCard({
    required this.name,
    required this.imageUrl, 
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: 
        Container(
          width: 72, // 🔥 largeur mini
          margin: const EdgeInsets.only(right: 8),
          child: Column(
            children: [ 
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 70,
                  height: 60, // 🔥 image mini carrée
                  child: imageUrl.isEmpty
                      ? Container(color: Colors.grey[300])
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                        ),
                )
                ), 
              Text(name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1,)  
            ],
          ),
        )
        
      );
  }
}

class _MiniPromoProductCard extends StatelessWidget {
  final String name;
  final String imageUrl; 
  final onTap;

  const _MiniPromoProductCard({
    required this.name,
    required this.imageUrl, 
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: 
        Container(
          width: 70,  // 🔥 hauteur mini
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red), // 🔥 bordure rouge pour les promos
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [ 
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 70,
                  height: 60, // 🔥 image mini carrée
                  child: imageUrl.isEmpty
                      ? Container(color: Colors.grey[300])
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                        ),
                )
                ), 
              Text(name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1,)  
            ],
          ),
        )
        
      );
  }
}