import 'package:flutter/material.dart';
import '../models/cliente.dart';
import '../services/cliente_service.dart';

class ClienteFormScreen extends StatefulWidget {
  final Cliente? cliente;

  const ClienteFormScreen({super.key, this.cliente});

  @override
  State<ClienteFormScreen> createState() => _ClienteFormScreenState();
}

class _ClienteFormScreenState extends State<ClienteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _cpfCnpjController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _enderecoController = TextEditingController();
  final _observacoesController = TextEditingController();
  final ClienteService _service = ClienteService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.cliente != null) {
      _nomeController.text = widget.cliente!.nome;
      _cpfCnpjController.text = widget.cliente!.cpfCnpj;
      _telefoneController.text = widget.cliente!.telefone;
      _emailController.text = widget.cliente!.email ?? '';
      _enderecoController.text = widget.cliente!.endereco ?? '';
      _observacoesController.text = widget.cliente!.observacoes ?? '';
    }
  }

  Future<void> _salvar() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final cliente = Cliente(
          id: widget.cliente?.id,
          nome: _nomeController.text.trim(),
          cpfCnpj: _cpfCnpjController.text.trim(),
          telefone: _telefoneController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          endereco: _enderecoController.text.trim().isEmpty ? null : _enderecoController.text.trim(),
          observacoes: _observacoesController.text.trim().isEmpty ? null : _observacoesController.text.trim(),
          dataCadastro: widget.cliente?.dataCadastro,
        );

        if (widget.cliente == null) {
          await _service.addCliente(cliente);
        } else {
          await _service.updateCliente(cliente);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cliente ${widget.cliente == null ? 'cadastrado' : 'atualizado'} com sucesso!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cliente == null ? 'Novo Cliente' : 'Editar Cliente'),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(_nomeController, 'Nome completo *', Icons.person, validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null),
              const SizedBox(height: 12),
              _buildTextField(_cpfCnpjController, 'CPF/CNPJ *', Icons.badge, validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null),
              const SizedBox(height: 12),
              _buildTextField(_telefoneController, 'Telefone *', Icons.phone, keyboardType: TextInputType.phone, validator: (v) => v!.isEmpty ? 'Campo obrigatório' : null),
              const SizedBox(height: 12),
              _buildTextField(_emailController, 'E-mail', Icons.email, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _buildTextField(_enderecoController, 'Endereço', Icons.location_on),
              const SizedBox(height: 12),
              _buildTextField(_observacoesController, 'Observações', Icons.note, maxLines: 3),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _salvar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF97316),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Salvar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF0F172A)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.all(16),
      ),
      validator: validator,
    );
  }
}