import 'package:flutter/material.dart';
import '../../data/repositories/promotion_repository.dart';
import '../../domain/models/promotion_model.dart';
import 'promotion_detail_screen.dart';
import 'promotion_form_screen.dart';

class PromotionsListScreen extends StatefulWidget {
  const PromotionsListScreen({required this.repository, super.key});
  static const path = '/profile/promotions';
  static const name = 'promotions';
  final PromotionRepository repository;
  @override State<PromotionsListScreen> createState() => _PromotionsListScreenState();
}

class _PromotionsListScreenState extends State<PromotionsListScreen> {
  final _q = TextEditingController();
  bool? _active;
  String? _type;
  List<PromotionModel> _items = [];
  bool _loading = true;
  @override void initState(){super.initState();_load();}
  Future<void> _load() async {setState(()=>_loading=true);try{_items=await widget.repository.list(q:_q.text.trim().isEmpty?null:_q.text.trim(),isActive:_active,type:_type);}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));}if(mounted)setState(()=>_loading=false);} 
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('Promociones')),floatingActionButton:FloatingActionButton.extended(onPressed:() async{final ok=await Navigator.push(context,MaterialPageRoute(builder:(_)=>PromotionFormScreen(repository: widget.repository)));if(ok==true)_load();},label:const Text('Nueva'),icon:const Icon(Icons.add)),body:Column(children:[Padding(padding:const EdgeInsets.all(12),child:Column(children:[TextField(controller:_q,decoration:InputDecoration(prefixIcon:const Icon(Icons.search),hintText:'Buscar por nombre',suffixIcon:IconButton(onPressed:_load,icon:const Icon(Icons.refresh)))),const SizedBox(height:8),Row(children:[Expanded(child:DropdownButtonFormField<bool?>(value:_active,decoration:const InputDecoration(labelText:'Estado'),items:const [DropdownMenuItem(value:null,child:Text('Todas')),DropdownMenuItem(value:true,child:Text('Activas')),DropdownMenuItem(value:false,child:Text('Inactivas'))],onChanged:(v){_active=v;_load();})),const SizedBox(width:8),Expanded(child:TextField(decoration:const InputDecoration(labelText:'Tipo'),onChanged:(v){_type=v.trim().isEmpty?null:v.trim();}))])])),Expanded(child:_loading?const Center(child:CircularProgressIndicator()):ListView.builder(itemCount:_items.length,itemBuilder:(_,i){final p=_items[i];return Card(child:ListTile(title:Text(p.name),subtitle:Text('${p.type} · prioridad ${p.priority}'),trailing:Switch(value:p.isActive,onChanged:(_){widget.repository.toggle(p.id).then((_)=>_load());}),onTap:() async{await Navigator.push(context,MaterialPageRoute(builder:(_)=>PromotionDetailScreen(repository: widget.repository,promotionId:p.id)));_load();}));}))]));
}
